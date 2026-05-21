# Feature reference

Every patient is described by the struct returned by `src/features/extract_patient_features.m`. Each field of that struct becomes a column in `features_master.xlsx` and a candidate predictor for the classifier in step 5.

This document lists every feature, the source function and a short description.

---

## Archetype correlations

These are the four correlations of the patient's averaged VCG loop against the four subtype archetypes. The archetype of the patient's own subtype is computed in a Leave-One-Out fashion so that the patient is never part of his own archetype.

| Field | Source | Description |
|---|---|---|
| `correlation_C_CW` | `intergroup_correlation` | Correlation against the C_CW archetype |
| `correlation_C_CCW` | `intergroup_correlation` | Correlation against the C_CCW archetype |
| `correlation_PM_CW` | `intergroup_correlation` | Correlation against the PM_CW archetype |
| `correlation_PM_CCW` | `intergroup_correlation` | Correlation against the PM_CCW archetype |

---

## Geometric features

Computed from the XY (frontal) or XZ (transversal) projections of the averaged VCG loop.

| Field | Source | Description |
|---|---|---|
| `max_vector` | `max_vector` | Maximum 3-D norm of the loop (after zero-meaning) |
| `complexity` | `geometric_complexity` | `perimetro_vcg / perimetro_elipse` (>1 = crinkled loop) |

---

## Linear-velocity features

Instantaneous Euclidean velocity along the loop, smoothed with a Savitzky-Golay filter.

| Field | Source | Description |
|---|---|---|
| `OCC_T` | `velocity_features` | Slow-Velocity Percentage Of Time (fraction of loop time in slow zones) |
| `peak_differences` | `velocity_features` | `max(v) - min(v)` |
| `average_homogeneity` | `velocity_features` | `(max - min) / mean(v)` |
| `kurtosis` | `velocity_features` | Kurtosis of the velocity distribution |
| `AUC_v` | `velocity_features` | `trapz(v)` (energy proxy) |
| `fastest_direction` | `velocity_features` | Dominant axis index in the slowest zone |
| `sign` | `velocity_features` | Sign of the fastest direction component |

---

## Angular-velocity features

Sample-to-sample angle between consecutive 3-D VCG vectors.

| Field | Source | Description |
|---|---|---|
| `homogeneidad_ang_media` | `angular_velocity_features` | `(max - min) / mean` |
| `Kurtosis_ang` | `angular_velocity_features` | Kurtosis of the angular velocity |
| `AUC_w` | `angular_velocity_features` | `trapz(v_ang)` |

---

## Block-wise means

Mean of the linear velocity within four pre-defined time windows. The windows are hard-coded in `extract_patient_features.m`.

| Field | Description |
|---|---|
| `mean_v` | Mean of the linear velocity over the whole loop |
| `mean_v_1stSeg` | Mean linear velocity over samples 70-110 |
| `mean_v_2stSeg` | Mean linear velocity over samples 400-490 |
| `mean_w` | Mean of the angular velocity over the whole loop |
| `mean_w_1stSeg` | Mean angular velocity 1st segment |
| `mean_w_2stSeg` | Mean angular velocity over 2nd segment |

---

## Clinical features (optional)

These are NOT computed by `extract_patient_features.m`; they come from the hospital clinical spreadsheet and must be merged into `features_master.xlsx` externally before running the classifier with `USE_CLINICAL_DATA = true`.

| Field | Description |
|---|---|
| `Sex` | Sex (0 = male, 1 = female) |
| `age` | Age (years) |
| `BMI` | Body Mass Index |
| `HTN` | Hypertension (0/1) |
| `CHADSVASC` | CHA2DS2-VASc score |
| `LVEF` | Left ventricular ejection fraction |
| `NO_AF`, `Paroxysmal_AF`, `Persistent_AF` | One-hot encoding of prior atrial fibrillation history |

Clinical features are **not** distributed in this repository.
