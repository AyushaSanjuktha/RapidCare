# Data Directory

This project uses the **"Collected and Categorized Wound Images Dataset"** from Kaggle:

> https://www.kaggle.com/datasets/ibrahimfateen/wound-classification

The dataset is **not** downloaded automatically (no Kaggle credentials are required by
this repo, and we never commit datasets). You must download and place it here yourself.

## Step 1 — Download

Either:

**Option A — Browser:** go to the Kaggle link above, click *Download*, unzip the file.

**Option B — Kaggle CLI:**
```bash
pip install kaggle
# put your kaggle.json API token at ~/.kaggle/kaggle.json first
kaggle datasets download -d ibrahimfateen/wound-classification -p data/
unzip data/wound-classification.zip -d data/
```

## Step 2 — Arrange into class folders

The training pipeline discovers class names **dynamically from folder names** — nothing
is hard-coded. Arrange the images so that the layout looks like:

```
data/
└── raw/
    ├── Abrasion/
    │   ├── img001.jpg
    │   └── ...
    ├── Bruise/
    │   └── ...
    ├── Cut/  (or Laceration/ — whatever folders the dataset ships)
    │   └── ...
    └── ...
```

> **Tip:** the exact folder names inside the Kaggle zip may differ (they are whatever
> the dataset author chose). Just make sure each class is its own sub-folder under
> `data/raw/`. If the zip has an extra nesting level (e.g. `data/raw/Wounds/train/...`),
> move the folders that directly contain images up to `data/raw/` level.

## Step 3 — Verify

Run the checker script to validate the layout, count images per class, and detect
corrupt files:

```bash
python scripts/check_dataset.py
```

It will print the discovered class names, per-class image counts, and any invalid
images. Training refuses to start until at least 2 valid class folders exist.

## Files in this folder

- `raw/` — your downloaded, per-class image folders (git-ignored)
- `processed/` — reserved for any preprocessed artifacts (currently unused)
