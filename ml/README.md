# ML Pipeline

MobileNetV2 transfer-learning pipeline for injury/wound image classification.

## Workflow

```
data/raw/<ClassName>/*.jpg          (you place the Kaggle dataset here)
        │
        ▼
scan_dataset()                      discover classes from folders (dynamic)
        │                           filter corrupt images (PIL verify)
        ▼
stratified_split()                  70% train / 15% val / 15% test
        │
        ▼
MobileNetV2 (ImageNet, no top)      frozen base
  + RandomFlip / RandomRotation / RandomZoom / RandomTranslation
                                              (realistic augmentation)
  + Rescaling 1/127.5, offset -1    (preprocess_input equivalent, inside model)
  + GlobalAveragePooling2D
  + Dropout(0.3)
  + Dense(n_classes, softmax)
        │
        ├─ Stage 1: train head only            (Adam 1e-3, ≤15 epochs)
        └─ Stage 2: fine-tune last block       (Adam 1e-5, ≤15 epochs)
        │
        ▼
models/best_model.keras             (augmentation + rescaling INSIDE the graph)
models/class_names.json             (discovered class list)
models/metrics.json                 (serving-TTA accuracy, precision, recall, F1, per-class)
models/confusion_matrix.png         (from ml/evaluate.py)
```

**Why preprocessing lives inside the model:** the saved `.keras` file applies the
exact same augmentation/rescaling at inference as during training — there is no
possibility of train/serve preprocessing skew, and serving code stays trivial.

## Commands

```bash
# activate the project venv first
source .venv/bin/activate

# 1. check dataset layout / counts / corrupt files
python scripts/check_dataset.py

# 2. train (recommended balanced, augmented two-stage training)
python ml/train.py

# 3. evaluate on the held-out test split + confusion matrix
python ml/evaluate.py

# 4. predict a single image
python ml/predict.py data/raw/<SomeClass>/some_image.jpg

# 5. verify artifacts are servable
python scripts/check_model.py
```

## Metrics note

Multiclass metrics are reported **macro** (equal weight per class — important when
classes are imbalanced) and **weighted** (proportional to class support). Accuracy
alone is misleading on imbalanced medical-adjacent data, so F1 is the headline
number to quote in your report/viva.

## Scope disclaimer

This model performs **image classification only**. Its output is a class label and
a softmax confidence — it is *not* a medical diagnosis, and model confidence is
**not** medical severity. In this system severity is entered/confirmed by a human
responder; the model output is only an AI-assisted triage hint.
