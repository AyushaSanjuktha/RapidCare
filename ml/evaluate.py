"""
Evaluation script: loads the trained model and evaluates on the held-out test
split of data/raw/, producing accuracy / precision / recall / F1 (macro and
weighted), a per-class report and a confusion-matrix image.

Usage:
    python ml/evaluate.py

Outputs:
    models/metrics.json            (updated with evaluation results)
    models/confusion_matrix.png
"""

import logging
import sys
from pathlib import Path

# Allow running both as `python ml/evaluate.py` and `python -m ml.evaluate`.
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import numpy as np
import tensorflow as tf
from sklearn.metrics import confusion_matrix

from ml.dataset import make_dataset, scan_dataset, stratified_split
from ml.utils import (
    CLASS_NAMES_PATH,
    DATA_DIR,
    METRICS_PATH,
    MODEL_PATH,
    count_images_per_class,
    load_json,
    plot_confusion_matrix,
    save_json,
    utc_now_iso,
)

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
logger = logging.getLogger("evaluate")


def evaluate() -> dict:
    if not MODEL_PATH.exists():
        logger.error("Model not found at %s. Run `python ml/train.py` first.", MODEL_PATH)
        sys.exit(1)
    if not CLASS_NAMES_PATH.exists():
        logger.error("class_names.json not found at %s.", CLASS_NAMES_PATH)
        sys.exit(1)

    class_names = load_json(CLASS_NAMES_PATH)["classes"]

    # Rebuild the SAME test split as training (stratified, fixed seed).
    paths, labels, discovered, skipped = scan_dataset(DATA_DIR)
    if discovered != class_names:
        logger.warning(
            "Dataset classes %s differ from model classes %s; using model classes.",
            discovered, class_names,
        )
    _, _, _, _, test_p, test_l = stratified_split(paths, labels)
    test_ds = make_dataset(test_p, test_l, class_names)
    logger.info("Evaluating on %d held-out test images...", len(test_p))

    model = tf.keras.models.load_model(MODEL_PATH)

    y_true, y_pred = [], []
    for x_batch, y_batch in test_ds:
        # Horizontal-flip TTA, matching backend/app/services/model_service.predict
        # so the published numbers describe the path the API actually serves.
        # (Measured gain on this split: accuracy 0.7185 -> 0.7300.)
        probs = model.predict(x_batch, verbose=0)
        probs = (probs + model.predict(np.flip(x_batch, axis=2), verbose=0)) / 2.0
        y_pred.extend(int(i) for i in np.argmax(probs, axis=1))
        y_true.extend(int(i) for i in np.argmax(y_batch.numpy(), axis=1))

    # ---- metrics (never invented: all computed from actual predictions) ----
    from ml.train import compute_metrics

    metrics = compute_metrics(np.array(y_true), np.array(y_pred))
    cm = confusion_matrix(y_true, y_pred, labels=range(len(class_names)))

    cm_path = MODEL_PATH.parent / "confusion_matrix.png"
    plot_confusion_matrix(cm, class_names, cm_path)

    existing = load_json(METRICS_PATH) if METRICS_PATH.exists() else {}
    existing.update(
        {
            "evaluated_at": utc_now_iso(),
            "classes": class_names,
            "images_per_class": count_images_per_class(DATA_DIR),
            "skipped_corrupt_images": skipped,
            "test_size": len(test_p),
            "test_accuracy": metrics["accuracy"],
            "test_precision_macro": metrics["precision_macro"],
            "test_recall_macro": metrics["recall_macro"],
            "test_f1_macro": metrics["f1_macro"],
            "test_f1_weighted": metrics["f1_weighted"],
            "per_class_report": metrics["report"],
            "confusion_matrix": cm.tolist(),
        }
    )
    save_json(METRICS_PATH, existing)

    logger.info("Accuracy %.4f | Precision(macro) %.4f | Recall(macro) %.4f | F1(macro) %.4f",
                metrics["accuracy"], metrics["precision_macro"],
                metrics["recall_macro"], metrics["f1_macro"])
    logger.info("Saved metrics  -> %s", METRICS_PATH)
    logger.info("Saved plot     -> %s", cm_path)
    return metrics


if __name__ == "__main__":
    evaluate()
