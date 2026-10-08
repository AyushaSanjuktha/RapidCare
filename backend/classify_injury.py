"""
Wound / injury image classifier — matches the preprocessing used at training time.
The [-1, 1] rescaling is baked into the saved model graph.
"""

import io
import json
import os
import threading
from pathlib import Path

import numpy as np
from PIL import Image
import tensorflow as tf

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = Path(BASE_DIR).parent

IMG_SIZE = (224, 224)

# Test-time augmentation: average the prediction over the original image and a
# horizontal flip of it. Set CLASSIFY_TTA=0 to disable (e.g. to compare or when
# the extra forward pass is not wanted).
TTA_ENABLED = os.getenv("CLASSIFY_TTA", "1").lower() not in {"0", "false", "no"}


# The model is ~9.5 MB and loading it takes ~2 s, so it is loaded once and
# reused for every request instead of being re-read from disk per prediction.
_model = None
_model_lock = threading.Lock()
_class_names = None


def _model_dir() -> Path:
    """Return the one approved model release directory.

    Defaults to ``RapidCare/models``. Deployments may instead set
    ``INJURY_MODEL_DIR``; a relative value is resolved from the RapidCare
    project root, not from the process working directory.
    """
    configured = os.getenv("INJURY_MODEL_DIR")
    if not configured:
        return PROJECT_ROOT / "models"
    path = Path(configured).expanduser()
    return path if path.is_absolute() else (PROJECT_ROOT / path).resolve()


def _load_model():
    """Load the Keras model once (thread-safe) and reuse it afterwards."""
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:
                model_path = _model_dir() / "best_model.keras"
                if not model_path.exists():
                    raise FileNotFoundError(
                        f"Model not found at {model_path}. "
                        "Train a model or set INJURY_MODEL_DIR to an approved model release."
                    )
                _model = tf.keras.models.load_model(model_path, compile=False)
    return _model


def _load_class_names():
    """Read and cache the class-name list once."""
    global _class_names
    if _class_names is None:
        class_names_path = _model_dir() / "class_names.json"
        if not class_names_path.exists():
            raise FileNotFoundError(
                f"Class names not found at {class_names_path}. "
                "Train a model or set INJURY_MODEL_DIR to an approved model release."
            )
        _class_names = json.loads(class_names_path.read_text())["classes"]
    return _class_names


def _preprocess(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize(IMG_SIZE)
    arr = np.asarray(img, dtype=np.float32)
    return arr[np.newaxis, ...]  # shape (1, 224, 224, 3)


def _predict_probs(model, batch: np.ndarray) -> np.ndarray:
    """
    Class probabilities for one batch, optionally averaged over a horizontal
    flip (test-time augmentation). Uses the same preprocessing as training
    (the [-1, 1] rescaling lives inside the saved model graph).

    The flip average is cheap and reduces variance, matching ml/evaluate.py.
    """
    probs = model.predict(batch, verbose=0)
    if TTA_ENABLED:
        probs = (probs + model.predict(np.flip(batch, axis=2), verbose=0)) / 2.0
    return probs


def classify_injury(image_bytes: bytes) -> dict:
    """
    Run inference on raw image bytes.
    Returns a dict with the predicted class, confidence, and per-class probabilities.
    """
    model = _load_model()
    class_names = _load_class_names()

    batch = _preprocess(image_bytes)
    probs = _predict_probs(model, batch)[0]
    idx = int(np.argmax(probs))

    all_probs = {cls: round(float(p), 4) for cls, p in zip(class_names, probs)}

    return {
        "injury_type": class_names[idx],
        "confidence": round(float(probs[idx]), 4),
        "all_probabilities": all_probs,
    }
