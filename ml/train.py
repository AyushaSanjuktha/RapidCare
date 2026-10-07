"""
Training script: MobileNetV2 transfer learning for wound/injury classification.

Pipeline:
    1. Validate dataset path, discover class names from folder structure
    2. Scan + filter corrupt images, stratified train/val/test split
    3. Oversample the train split to a balanced class distribution by default
    4. Stage 1: train a new classification head (MobileNetV2 base frozen)
    5. Stage 2: fine-tune the last MobileNetV2 block with a tiny learning rate
    6. Save best model, class_names.json and metrics.json

Usage:
    python ml/train.py                              # recommended balanced run
    python ml/train.py --no-oversample              # ablation: original sampling
    python ml/train.py --no-strong-aug              # ablation: milder augmentation
"""

import argparse
import logging
import sys
from pathlib import Path

# Allow running both as `python ml/train.py` and `python -m ml.train`.
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers

from ml.dataset import make_dataset, oversample_to_balance, scan_dataset, stratified_split
from ml.utils import (
    CLASS_NAMES_PATH,
    DATA_DIR,
    IMG_SIZE,
    METRICS_PATH,
    MODEL_PATH,
    MODELS_DIR,
    SEED,
    count_images_per_class,
    save_json,
    set_seed,
    utc_now_iso,
)


def compute_class_weights(labels: list, num_classes: int) -> dict:
    """
    Balanced class weights for the loss: w_c = N / (num_classes * count_c).

    minority classes (e.g. Cut with 97 images) contribute more per sample than
    majority ones (e.g. Pressure Wounds with 599) so the softmax head does not
    simply learn the class priors. Labels are integer indices.
    """
    counts = np.bincount(np.asarray(labels, dtype=np.int64), minlength=num_classes)
    if np.any(counts == 0):
        missing = [i for i, c in enumerate(counts) if c == 0]
        raise ValueError(f"No training samples for class indices {missing}.")
    total = counts.sum()
    weights = total / (num_classes * counts)
    return {int(i): float(w) for i, w in enumerate(weights)}

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
logger = logging.getLogger("train")


# ----------------------------------------------------------------- model ----


def build_model(num_classes: int, strong_aug: bool = True) -> tf.keras.Model:
    """
    MobileNetV2 transfer-learning model.

    The input pipeline (augmentation + [-1,1] rescaling) is INSIDE the model:
      * augmentation is active only in training mode,
      * rescaling is identical at train and inference time (no skew),
      * the saved .keras file is fully self-contained for serving.

    strong_aug=True adds mild brightness/contrast jitter, translation and a
    wider zoom. These make the classifier less dependent on lighting and on a
    wound being centred in the frame.
    Deliberately still realistic for wound photos: no grid distortion or
    cutout that could erase the wound itself.
    """
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=IMG_SIZE + (3,),
        include_top=False,          # drop ImageNet's 1000-class classifier
        weights="imagenet",
    )
    base_model.trainable = False    # stage 1: train the new head only

    inputs = tf.keras.Input(shape=IMG_SIZE + (3,), name="image")  # 0-255 RGB
    x = layers.RandomFlip("horizontal")(inputs)
    x = layers.RandomRotation(0.08 if strong_aug else 0.05)(x)  # small on purpose
    x = layers.RandomZoom(0.2 if strong_aug else 0.1)(x)
    if strong_aug:
        x = layers.RandomTranslation(0.08, 0.08)(x)
        x = layers.RandomBrightness(0.15)(x)
        x = layers.RandomContrast(0.15)(x)
    # [-1, 1] rescale, identical to tf.keras.applications.mobilenet_v2.preprocess_input
    x = layers.Rescaling(scale=1.0 / 127.5, offset=-1.0)(x)
    x = base_model(x, training=False)    # keep BatchNorm stats frozen
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation="softmax")(x)

    return models.Model(inputs, outputs, name="injury_classifier")


# ----------------------------------------------------------------- train ----


def train(head_epochs=20, fine_tune_epochs=15, oversample=True, strong_aug=True) -> dict:
    set_seed(SEED)
    tf.random.set_seed(SEED)

    # 1-2. dataset -----------------------------------------------------------
    paths, labels, class_names, skipped = scan_dataset(DATA_DIR)
    counts = count_images_per_class(DATA_DIR)
    logger.info("Discovered %d classes: %s", len(class_names), class_names)
    logger.info("Images per class: %s", counts)
    if skipped:
        logger.warning("Skipped %d corrupt/unreadable images", skipped)

    train_p, train_l, val_p, val_l, test_p, test_l = stratified_split(paths, labels)
    logger.info(
        "Split -> train: %d | val: %d | test: %d", len(train_p), len(val_p), len(test_p)
    )

    # Optional: oversample the TRAIN split to a perfectly balanced
    # distribution. Val/test stay untouched so the evaluation is honest.
    oversampled_added = 0
    if oversample:
        before = len(train_p)
        train_p, train_l = oversample_to_balance(train_p, train_l, seed=SEED)
        oversampled_added = len(train_p) - before
        logger.info(
            "Oversampling train split: %d -> %d samples (+%d repeats)",
            before, len(train_p), oversampled_added,
        )

    train_ds = make_dataset(train_p, train_l, class_names, training=True)
    val_ds = make_dataset(val_p, val_l, class_names)
    test_ds = make_dataset(test_p, test_l, class_names)

    # Class weighting: counteract the imbalanced class distribution so rare
    # classes (e.g. Cut) count as much per epoch as common ones (e.g. Pressure
    # Wounds). Weights come from the TRAIN split only — val/test stay natural.
    class_weights = compute_class_weights(train_l, num_classes=len(class_names))
    logger.info("Class weights: %s", {
        class_names[i]: round(w, 3) for i, w in class_weights.items()
    })

    # 3. stage 1: classification head ----------------------------------------
    model = build_model(num_classes=len(class_names), strong_aug=strong_aug)
    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-3),
        # A little label smoothing reduces the very high-confidence mistakes
        # seen on visually similar wound classes without changing the labels.
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.05),
        metrics=[
            tf.keras.metrics.CategoricalAccuracy(name="accuracy"),
            tf.keras.metrics.F1Score(average="macro", name="macro_f1"),
        ],
    )
    model.summary(print_fn=logger.info)

    checkpoint_stage1 = tf.keras.callbacks.ModelCheckpoint(
        filepath=str(MODELS_DIR / "best_model.keras"),
        monitor="val_macro_f1", mode="max", save_best_only=True,
    )
    callbacks_stage1 = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_macro_f1", mode="max", patience=5, restore_best_weights=True
        ),
        checkpoint_stage1,
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_macro_f1", mode="max", factor=0.5, patience=2, min_lr=1e-6
        ),
    ]

    logger.info("=== Stage 1: training classification head ===")
    history1 = model.fit(train_ds, validation_data=val_ds, epochs=head_epochs,
                         callbacks=callbacks_stage1, class_weight=class_weights)

    # 4. stage 2: fine-tune the top of the base -------------------------------
    logger.info("=== Stage 2: fine-tuning last MobileNetV2 block ===")
    # Find the MobileNetV2 backbone programmatically (robust to Keras naming).
    base_model = next(
        layer for layer in model.layers if isinstance(layer, tf.keras.Model)
    )
    base_model.trainable = True
    fine_tune_from = 100  # keep earlier blocks frozen
    for layer in base_model.layers[:fine_tune_from]:
        layer.trainable = False

    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-5),  # very small on purpose
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.05),
        metrics=[
            tf.keras.metrics.CategoricalAccuracy(name="accuracy"),
            tf.keras.metrics.F1Score(average="macro", name="macro_f1"),
        ],
    )
    fine_tune_epochs_total = len(history1.epoch) + fine_tune_epochs
    checkpoint_stage2 = tf.keras.callbacks.ModelCheckpoint(
        filepath=str(MODELS_DIR / "best_model.keras"),
        monitor="val_macro_f1", mode="max", save_best_only=True,
    )
    # ModelCheckpoint is a new callback for stage 2. Carry the stage-1 best
    # score forward; otherwise it would overwrite the artifact after its first
    # fine-tuning epoch even if that epoch performed worse.
    checkpoint_stage2.best = max(history1.history["val_macro_f1"])
    callbacks_stage2 = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_macro_f1", mode="max", patience=4, restore_best_weights=True
        ),
        checkpoint_stage2,
    ]
    history2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=fine_tune_epochs_total,
        initial_epoch=len(history1.epoch),
        callbacks=callbacks_stage2,
        class_weight=class_weights,
    )

    # 5. Evaluate and publish the best validation checkpoint, not the final
    # epoch.  The previous implementation overwrote the checkpoint below with
    # the final in-memory weights, which could silently publish a worse model.
    model = tf.keras.models.load_model(MODEL_PATH)
    results = model.evaluate(test_ds, return_dict=True)
    y_true, y_pred = collect_predictions(model, test_ds)
    metrics = compute_metrics(y_true, y_pred)

    # Re-save only after loading the checkpoint so the serving artifact is
    # exactly the model selected by validation macro-F1.
    model.save(MODEL_PATH)
    save_json(CLASS_NAMES_PATH, {"classes": class_names})
    save_json(
        METRICS_PATH,
        {
            "trained_at": utc_now_iso(),
            "classes": class_names,
            "images_per_class": counts,
            "skipped_corrupt_images": skipped,
            "split_sizes": {
                "train": len(train_p), "validation": len(val_p), "test": len(test_p)
            },
            # Accuracy/F1 describe the same horizontal-flip TTA path that the
            # backend serves, rather than a different evaluator.
            "test_accuracy": metrics["accuracy"],
            "test_loss": float(results["loss"]),
            "test_precision_macro": metrics["precision_macro"],
            "test_recall_macro": metrics["recall_macro"],
            "test_f1_macro": metrics["f1_macro"],
            "test_f1_weighted": metrics["f1_weighted"],
            "per_class_report": metrics["report"],
            "class_weights": {class_names[i]: round(w, 4) for i, w in class_weights.items()},
            "training_config": {
                "oversample": oversample,
                "oversampled_added": oversampled_added,
                "strong_aug": strong_aug,
                "label_smoothing": 0.05,
                "selection_metric": "validation macro F1",
            },
        },
    )

    logger.info("Test accuracy (serving TTA): %.4f | F1 (macro): %.4f", metrics["accuracy"], metrics["f1_macro"])
    logger.info("Saved model  -> %s", MODEL_PATH)
    logger.info("Saved classes -> %s", CLASS_NAMES_PATH)
    logger.info("Saved metrics -> %s", METRICS_PATH)
    return metrics


def collect_predictions(model, test_ds):
    """Run serving-equivalent horizontal-flip TTA inference on the test set."""
    import numpy as np

    y_true, y_pred = [], []
    for x_batch, y_batch in test_ds:
        probs = model.predict(x_batch, verbose=0)
        probs = (probs + model.predict(np.flip(x_batch, axis=2), verbose=0)) / 2.0
        y_pred.extend(int(i) for i in np.argmax(probs, axis=1))
        y_true.extend(int(i) for i in np.argmax(y_batch.numpy(), axis=1))
    return np.array(y_true), np.array(y_pred)


def compute_metrics(y_true, y_pred) -> dict:
    """Accuracy + macro/weighted precision, recall, F1 and per-class report."""
    from sklearn.metrics import (
        accuracy_score,
        classification_report,
        f1_score,
        precision_score,
        recall_score,
    )

    return {
        "accuracy": accuracy_score(y_true, y_pred),
        "precision_macro": float(precision_score(y_true, y_pred, average="macro", zero_division=0)),
        "recall_macro": float(recall_score(y_true, y_pred, average="macro", zero_division=0)),
        "f1_macro": float(f1_score(y_true, y_pred, average="macro", zero_division=0)),
        "f1_weighted": float(f1_score(y_true, y_pred, average="weighted", zero_division=0)),
        "report": classification_report(y_true, y_pred, output_dict=True, zero_division=0),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train the injury classifier")
    parser.add_argument(
        "--no-oversample", action="store_false", dest="oversample", default=True,
        help="disable balanced oversampling (not recommended)",
    )
    parser.add_argument(
        "--no-strong-aug", action="store_false", dest="strong_aug", default=True,
        help="use milder augmentation (not recommended)",
    )
    args = parser.parse_args()

    try:
        train(oversample=args.oversample, strong_aug=args.strong_aug)
    except (FileNotFoundError, ValueError) as exc:
        logger.error("%s", exc)
        sys.exit(1)
