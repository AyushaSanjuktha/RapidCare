"""
Shared helpers for the ML pipeline: paths, constants, JSON I/O, seeds, plots.

Kept deliberately small and readable so the flow is easy to explain in a viva.
"""

import json
import random
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

# ---------------------------------------------------------------- paths ----
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "raw"
MODELS_DIR = PROJECT_ROOT / "models"
MODEL_PATH = MODELS_DIR / "best_model.keras"
CLASS_NAMES_PATH = MODELS_DIR / "class_names.json"
METRICS_PATH = MODELS_DIR / "metrics.json"

IMG_SIZE = (224, 224)   # MobileNetV2 native input size
BATCH_SIZE = 32
SEED = 42

# ------------------------------------------------------------- utilities ----


def set_seed(seed: int = SEED) -> None:
    """Seed python/numpy for reproducible splits and shuffling."""
    random.seed(seed)
    np.random.seed(seed)


def save_json(path: Path, data: dict) -> None:
    """Write a dict to JSON with pretty formatting (creates parent dirs)."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def load_json(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def utc_now_iso() -> str:
    """Timestamp string used to tag metrics artifacts."""
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def count_images_per_class(data_dir: Path) -> dict:
    """Return {class_name: image_count} from one-folder-per-class layout."""
    counts = {}
    for class_dir in sorted(p for p in Path(data_dir).iterdir() if p.is_dir()):
        n = sum(
            1
            for f in class_dir.iterdir()
            if f.is_file() and f.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        )
        counts[class_dir.name] = n
    return counts


def plot_confusion_matrix(cm: np.ndarray, class_names: list, out_path: Path) -> None:
    """Save a labelled confusion-matrix heatmap (seaborn) to out_path."""
    import matplotlib

    matplotlib.use("Agg")  # headless: no display needed
    import matplotlib.pyplot as plt
    import seaborn as sns

    fig, ax = plt.subplots(figsize=(max(8, len(class_names)), max(6, len(class_names) * 0.8)))
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=class_names,
        yticklabels=class_names,
        ax=ax,
    )
    ax.set_xlabel("Predicted label")
    ax.set_ylabel("True label")
    ax.set_title("Confusion Matrix")
    plt.tight_layout()
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=120)
    plt.close(fig)
