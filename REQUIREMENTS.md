# Requirements

## MATLAB Version

This code has been developed and tested on **MATLAB R2023b** (or newer).
Earlier versions may work but are not guaranteed.

## Required MATLAB Toolboxes

The pipeline relies on the following official MATLAB toolboxes:

| Toolbox | Used for |
|---|---|
| Signal Processing Toolbox | Filtering (`butter`, `cheby2`, `filtfilt`), resampling (`resample`), autocorrelation (`xcorr`), peak detection (`findpeaks`), Savitzky-Golay smoothing (`sgolayfilt`) |
| Statistics and Machine Learning Toolbox | Classifiers (`fitctree`, `fitcensemble`, `fitcecoc`, `templateSVM`, `templateLinear`, `templateTree`), cross-validation (`cvpartition`), ROC analysis (`perfcurve`), non-parametric tests (`signrank`, `ranksum`), PCA (`pca`), inverse beta (`betainv`) |

To check which toolboxes are installed in your MATLAB environment, run:

```matlab
ver
```

## External Dependencies

This repository includes third-party MATLAB functions originally developed by
other authors. They are bundled in `src/external/` for convenience and
reproducibility. See `THIRD_PARTY.md` for full attribution.

No external software packages (outside MATLAB) are needed to run the pipeline.

## Input Data Format

The pipeline expects:

- **ECG files**: 12-lead ECG recordings at 1000 Hz sampling rate, stored as
  text files (one lead per column or row; the loader transposes if needed).
  File naming convention: `ECG_<id>_<group>_<direction>.txt` where
  `<group>` is `C` (common, cavotricuspid isthmus) or `PM` (perimitral),
  and `<direction>` is `CW` (clockwise) or `CCW` (counter-clockwise).
- **Clinical data (optional)**: A spreadsheet with patient clinical variables.
  See `docs/PIPELINE.md` for the expected column names.

Patient data is **not** included in this repository for privacy reasons.

## Hardware

The pipeline runs on a standard desktop or laptop. No GPU is required.
Typical runtime on a single patient is a few seconds for feature extraction;
the full nested cross-validation classification step takes a few minutes
depending on the number of patients and hyperparameter combinations.
