# Pipeline overview

This document describes the end-to-end pipeline implemented in this
repository, from a raw 12-lead ECG of a flutter patient to the cascade
prediction of the four flutter subtypes.

The pipeline is organised as five orchestration scripts (`scripts/01_*` to
`scripts/05_*`) that call functions in `src/`. Each script can also be run
on its own; the input / output folders are configurable at the top of each
file.

---

## High-level diagram

```
   [raw 12-lead ECG]
          |
   01_preprocess_and_create_vcg.m
          |
          v
   [averaged VCG loop, 3 x L]
          |
   02_build_archetypes.m
          |
          v
   [4 subtype archetypes]
          |
   03_extract_patient_features.m
          |
          v
   [.mat per patient with full feature struct]
          |
   04_consolidate_features.m
          |
          v
   [features_master.xlsx]
          |   (optional: merge clinical data)
          v
   05_train_classifier.m
          |
          v
   [predictions, ROC, confusion matrices]
```

---

## Step-by-step

### 1. Preprocessing and VCG construction

`scripts/01_preprocess_and_create_vcg.m`

- Loads one raw ECG (12 leads at 1000 Hz) identified by its numeric
  patient code.
- Filters the signal: high-pass (`fpa`, 1.5 Hz) followed by low-pass
  (`lpf_ecg`, 30 Hz).
- Runs the automatic atrial-segment detector
  (`src/preprocessing/select_f_waves.m`) as a visual aid.
- Asks the user (via `ginput`) to mark the clean atrial segment with two
  clicks; this manual step is needed because the automatic detection can
  fail on noisy / atypical recordings.
- Applies the inverse Dower transform (`idowerT`) to obtain the VCG.
- Detects the cycle length by autocorrelation of lead X and averages
  every complete cycle.
- Closes the VCG loop and zero-means it.
- Writes the resulting 3 x L matrix to disk as
  `VCG_<id>_<group>_<direction>.txt`.

### 2. Archetype construction

`scripts/02_build_archetypes.m`

For each of the four flutter subtypes (`_C_CW`, `_C_CCW`, `_PM_CW`,
`_PM_CCW`):

- Loads every patient VCG of that subtype.
- (Optional) Runs a K-fold robustness check (set
  `ARCHETYPE_MODE = 'kfold'` at the top of the script).
- Builds the production archetype with `mode = 'all'`: average across all
  patients, then close the loop. Saves the result as
  `VCG_<group>_AVG.txt`.

The archetypes are the templates against which every new patient's VCG is
correlated in step 3.

### 3. Patient-level feature extraction

`scripts/03_extract_patient_features.m`

Two operating modes:

- **MODE A** (`SINGLE_PATIENT_CODE = []`): iterate over every patient and
  save one feature file per patient. Use this to prepare the dataset
  before training.

- **MODE B** (`SINGLE_PATIENT_CODE = <int>`): process a single new
  patient. Use this once the classifier has been trained and you want to
  apply it to a previously unseen patient.

For each patient the script:

- Calls `intergroup_correlation` to compute the four correlations of the
  patient's VCG against the four subtype archetypes. The archetype of the
  patient's own subtype is recomputed in a Leave-One-Out fashion so that
  the patient is never part of his own archetype.
- Calls `extract_patient_features` to compute every geometric and
  velocity descriptor.
- Saves the result as `resultado_total_<group>_paciente_<id>.mat`.

### 4. Spreadsheet consolidation

`scripts/04_consolidate_features.m`

- Reads every `resultado_total_*_paciente_*.mat` produced in step 3.
- Concatenates the patient feature structs into a single MATLAB table.
- Writes the table to disk as `features_master.xlsx` (one row per
  patient).

If you have clinical data (age, BMI, CHA2DS2-VASc, LVEF, comorbidities,
etc.), merge those columns into `features_master.xlsx` externally before
running step 5 with `USE_CLINICAL_DATA = true`. This repository does NOT
distribute the clinical data because of patient-privacy restrictions.

### 5. Cascade classification

`scripts/05_train_classifier.m`

- Reads `features_master.xlsx`.
- Selects the feature set: VCG-only or VCG + clinical, depending on the
  `USE_CLINICAL_DATA` flag.
- Runs `cascade_classification_pipeline`:
  - **Outer K-fold** for unbiased performance estimation.
  - **Inner 3-fold** for hyperparameter tuning.
  - Five candidate models: Decision Tree, Bagged Trees (Random Forest),
    AdaBoostM2, Penalised Logistic (Elastic Net), Linear SVM.
- Reports the cascade metrics:
  - **Block A**: substrate-level discrimination (C vs PM) with
    Clopper-Pearson exact 95% confidence intervals.
  - **Block B**: within-substrate direction discrimination (CCW vs CW),
    restricted to the patients whose substrate was correctly predicted.
    The 0 / 0 blocks in the 4 x 4 confusion matrix are structural (caused
    by the cascade filter, NOT by the model).
- Plots ROC curves (one-vs-rest and binary C vs PM) and confusion
  matrices for the Bag (Random Forest) model.
- Saves every prediction, score, ROC curve and confusion matrix to
  `models/classification_results.mat`.

---

## Expected data layout

The default configuration assumes the following folder layout (relative
to the repository root):

```
.
|-- data/
|   |-- ECGs/         <-- input: ECG_<id>_<group>_<direction>.txt
|   |-- VCGs/         <-- output of step 1
|   |-- archetypes/   <-- output of step 2
|   `-- features/     <-- output of step 3 (one .mat per patient)
|       `-- features_master.xlsx   <-- output of step 4
`-- models/
    `-- classification_results.mat <-- output of step 5
```

`data/` is in `.gitignore`, so patient files never end up in version
control. You can edit any of these paths at the top of each script if you
prefer a different layout.

---

## Reproducibility

- All folds and model trainings use a fixed RNG seed (`42` by default,
  configurable in `05_train_classifier.m`).
- The inner / outer fold partitions are stratified by class using
  `kfold_imbalanced_partition`, so every fold sees every subtype.
- The patient assignment to outer folds is verified at runtime: each
  patient appears in the outer test set exactly once.

---

## Manual steps that cannot be automated

1. The atrial-segment selection in step 1 (`ginput`) is intentional. The
   automatic F-wave detector is a visual aid; the final selection is up
   to the user, because noisy or atypical recordings can fool the
   detector.

2. Merging clinical data into `features_master.xlsx` (between steps 4
   and 5) is intentionally left to the user. The exact column names and
   coding conventions depend on the clinical spreadsheet provided by the
   hospital.
