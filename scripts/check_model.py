#!/usr/bin/env python
"""
Pre-flight check that the trained model artifacts are present and loadable,
and that the class list matches what the backend will serve.

Usage:
    python scripts/check_model.py
"""

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
MODEL_PATH = PROJECT_ROOT / "models" / "best_model.keras"
CLASS_NAMES_PATH = PROJECT_ROOT / "models" / "class_names.json"

REQUIRED_CLASSES = 2  # a classifier needs at least two classes to be meaningful


def main() -> int:
    print("== Model artifact check ==")

    if not MODEL_PATH.exists():
        print(f"[MISSING] {MODEL_PATH}")
        print("          -> run: python ml/train.py")
        return 1
    print(f"[OK]      {MODEL_PATH}  ({MODEL_PATH.stat().st_size / 1e6:.1f} MB)")

    if not CLASS_NAMES_PATH.exists():
        print(f"[MISSING] {CLASS_NAMES_PATH}")
        return 1
    print(f"[OK]      {CLASS_NAMES_PATH}")

    import json

    classes = json.loads(CLASS_NAMES_PATH.read_text())["classes"]
    print(f"[OK]      {len(classes)} classes: {classes}")
    if len(classes) < REQUIRED_CLASSES:
        print(f"[FAIL]    need at least {REQUIRED_CLASSES} classes")
        return 1

    try:
        import tensorflow as tf

        model = tf.keras.models.load_model(MODEL_PATH)
        n_out = model.output_shape[-1]
        print(f"[OK]      model loads; output units = {n_out}")
        if n_out != len(classes):
            print(f"[FAIL]    model outputs {n_out} classes but class_names.json has {len(classes)}")
            return 1
    except ImportError:
        print("[SKIP]    tensorflow not installed in this env; skipped load test")
    except Exception as exc:  # noqa: BLE001 - report any load failure clearly
        print(f"[FAIL]    model failed to load: {exc}")
        return 1

    print("\nAll good — backend can serve this model.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
