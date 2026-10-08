#!/usr/bin/env python
"""
Test the trained model on NEVER-SEEN images kept in data/new_images/<Class>/.

These files are excluded from training/validation/test splits — they only
exist to demonstrate how the model behaves on fresh inputs, which is what a
viva/demo will actually show.

Usage:
    python scripts/test_new_images.py
"""

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from PIL import Image  # noqa: E402

from ml.predict import predict_image  # same preprocessing as training  # noqa: E402

NEW_IMAGES_DIR = PROJECT_ROOT / "data" / "new_images"


def main() -> int:
    if not NEW_IMAGES_DIR.exists():
        print(f"[MISSING] {NEW_IMAGES_DIR} does not exist.")
        print("          Place fresh images in data/new_images/<ClassName>/ and re-run.")
        return 1

    results_path = PROJECT_ROOT / "models" / "new_images_results.json"
    rows, correct = [], 0

    print("== New-image (never-seen) test ==\n")
    for class_dir in sorted(p for p in NEW_IMAGES_DIR.iterdir() if p.is_dir()):
        images = sorted(
            f for f in class_dir.iterdir()
            if f.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        )
        for img_path in images:
            try:
                pred = predict_image(img_path)
            except Exception as exc:  # noqa: BLE001
                print(f"[ERROR] {img_path.name}: {exc}")
                continue

            hit = pred["injury_type"] == class_dir.name
            correct += hit
            rows.append(
                {
                    "file": str(img_path.relative_to(PROJECT_ROOT)),
                    "true_class": class_dir.name,
                    "predicted": pred["injury_type"],
                    "confidence": pred["confidence"],
                    "correct": hit,
                }
            )
            marker = "✓" if hit else "✗"
            print(
                f"  {marker} {img_path.name:<28} true={class_dir.name:<16} "
                f"pred={pred['injury_type']:<16} conf={pred['confidence']:.3f}"
            )

    total = len(rows)
    if total == 0:
        print("No images found to test.")
        return 1

    accuracy = correct / total
    print(f"\nNew-image accuracy: {correct}/{total} = {accuracy:.1%}")

    results_path.parent.mkdir(parents=True, exist_ok=True)
    results_path.write_text(json.dumps({"accuracy": accuracy, "results": rows}, indent=2))
    print(f"Saved -> {results_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
