"""
Single-image prediction CLI — uses the EXACT same preprocessing as training,
because augmentation/rescaling live inside the saved model graph itself.

Usage:
    python ml/predict.py path/to/image.jpg
"""

import json
import logging
import sys
from pathlib import Path

# Allow running both as `python ml/predict.py <img>` and `python -m ml.predict`.
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import numpy as np
import tensorflow as tf
from PIL import Image, UnidentifiedImageError

from ml.utils import CLASS_NAMES_PATH, IMG_SIZE, MODEL_PATH

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
logger = logging.getLogger("predict")


def preprocess_image(path: Path) -> np.ndarray:
    """
    Match serving time preprocessing:
    decode -> RGB -> resize to IMG_SIZE -> batch of 1, pixel values 0-255.
    (The [-1, 1] rescaling happens inside the model.)
    """
    with Image.open(path) as img:
        img = img.convert("RGB")  # handles grayscale / RGBA / palette images
        img = img.resize(IMG_SIZE)
        arr = np.asarray(img, dtype=np.float32)
    return arr[np.newaxis, ...]  # shape (1, 224, 224, 3)


def predict_image(path: Path, tta: bool = True) -> dict:
    """Predict one image using the same optional flip-TTA as the API."""
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Model not found at {MODEL_PATH}. Train it first: python ml/train.py"
        )
    if not CLASS_NAMES_PATH.exists():
        raise FileNotFoundError(
            f"Class names not found at {CLASS_NAMES_PATH}."
        )

    class_names = json.loads(CLASS_NAMES_PATH.read_text())["classes"]
    model = tf.keras.models.load_model(MODEL_PATH)
    batch = preprocess_image(Path(path))

    probs = model.predict(batch, verbose=0)
    if tta:
        probs = (probs + model.predict(np.flip(batch, axis=2), verbose=0)) / 2.0
    probs = probs[0]
    idx = int(np.argmax(probs))
    return {"injury_type": class_names[idx], "confidence": round(float(probs[idx]), 4)}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        logger.error("Usage: python ml/predict.py <path/to/image>")
        sys.exit(2)
    image_path = Path(sys.argv[1])
    try:
        result = predict_image(image_path)
    except (UnidentifiedImageError, FileNotFoundError, ValueError) as exc:
        logger.error("Prediction failed: %s", exc)
        sys.exit(1)
    print(json.dumps(result, indent=2))
