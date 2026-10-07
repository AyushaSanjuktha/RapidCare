#!/usr/bin/env python
"""
Dataset inspector: verifies the layout under data/raw/, discovers class names
from folder names (nothing hard-coded), counts images per class and detects
corrupt files. Run this before training.

Usage:
    python scripts/check_dataset.py
"""

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def main() -> int:
    from PIL import Image, UnidentifiedImageError

    data_dir = PROJECT_ROOT / "data" / "raw"
    print("== Dataset check ==")
    print(f"Looking for class folders in: {data_dir}\n")

    if not data_dir.exists():
        print(f"[MISSING] {data_dir} does not exist.")
        print("          Create it and place the Kaggle wound dataset inside")
        print("          (see data/README.md for exact steps).")
        return 1

    class_dirs = sorted(
        d for d in data_dir.iterdir() if d.is_dir()
        and any(f.suffix.lower() in VALID_EXTENSIONS for f in d.iterdir() if f.is_file())
    )
    if not class_dirs:
        print("[EMPTY]   No class folders with images found.")
        print("          Expected layout: data/raw/<ClassName>/*.jpg")
        print("          See data/README.md for how to arrange the dataset.")
        return 1

    print(f"[OK]      Discovered {len(class_dirs)} classes (from folder names):\n")

    total, corrupt_total = 0, 0
    for d in class_dirs:
        files = [f for f in sorted(d.iterdir()) if f.suffix.lower() in VALID_EXTENSIONS]
        corrupt = []
        for f in files:
            try:
                with Image.open(f) as img:
                    img.verify()
            except (UnidentifiedImageError, OSError, ValueError):
                corrupt.append(f.name)
        total += len(files)
        corrupt_total += len(corrupt)
        status = "[WARN]" if corrupt else "[OK]  "
        print(f"  {status} {d.name:<30} {len(files):>5} images"
              + (f"  ({len(corrupt)} corrupt: {corrupt[:3]}{'...' if len(corrupt) > 3 else ''})"
                 if corrupt else ""))

    print(f"\nTotal: {total} images | corrupt: {corrupt_total}")
    if len(class_dirs) < 2:
        print("[FAIL]   Need at least 2 class folders to train a classifier.")
        return 1

    print("\nDataset looks good — next step: python ml/train.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
