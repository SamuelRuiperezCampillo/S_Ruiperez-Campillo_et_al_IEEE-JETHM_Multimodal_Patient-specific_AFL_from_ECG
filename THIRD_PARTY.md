# Third-Party Code Attribution

This repository bundles several MATLAB functions that were **not** originally
developed by the authors of this work. They are included in `src/external/`
to make the pipeline reproducible out-of-the-box. All original authorship,
license terms, and citation requirements are preserved.

If you reuse any of these files outside this repository, please respect the
original authors' terms.

---

## `zero_mean.m`

- **Author:** Vicente Zarzoso Gascon-Pelegri
- **Year:** 1999
- **Purpose:** Removes the mean value from input signals (row-wise).

---

## `lpf_ecg.m`

- **Author:** J. J. Rieta (Universitat Politecnica de Valencia)
- **Year:** July 2000
- **Contact (historical):** jjrieta@eln.upv.es
- **Purpose:** Low-pass filtering of ECG signals using an order-8 Chebyshev
  Type II filter with bidirectional (zero-phase) filtering.

---

## `fpa.m`

- **Author:** Affiliated with the EP Analytics Lab / ITACA / UPV signal-processing
  group (uses `zero_mean.m` by V. Zarzoso).
- **Purpose:** High-pass (baseline-wander removal) filter for ECG signals,
  implemented with an order-3 Butterworth filter applied bidirectionally.

---

## `idowerT.m`

- **Author:** Gari D. Clifford
- **Year:** April 2006
- **Reference:** http://alum.mit.edu/www/gari/ecgtools
- **Purpose:** Inverse Dower transform to derive the Vectorcardiogram (VCG)
  from the standard 12-lead ECG.

---

## `compute_area_loop.m`

- **Authors:** Marina Crespo, Izan Segarra, Samuel Ruiperez-Campillo,
  Francisco Castells
- **Affiliation:** QCEP, ITACA, Universitat Politecnica de Valencia
- **Date:** 10/08/2022
- **Mandatory citation (per the original file):**

  > S. Ruiperez-Campillo, M. Crespo, F. Castells, A. Tormos, A. Guill,
  > A. Alberola, R. Cervigon, J. Heimer, F. J. Chorro, J. Millet, F. Castells.
  > "Evaluation and Assessment of Clique Arrangements for the Estimation of
  > Omnipolar Electrograms in High Density Electrode Arrays: An Experimental
  > Animal Model Study." *Physical and Engineering Sciences in Medicine* (2023).

- **Purpose:** Estimates the area enclosed by a 2D bipolar loop via
  trapezoidal integration per quadrant.

---

## `velocidad_VCG.m`

- **Source:** Internal code of the EP Analytics Lab / ITACA / UPV VCG analysis group.
- **Purpose:** Computes the instantaneous Euclidean velocity of the VCG loop
  and identifies the dominant direction of travel in the slowest region.

---

## `dibuja_VCG.m`

- **Source:** Internal plotting utility of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Visualisation of the VCG in 2D (frontal / transversal /
  sagittal planes) and 3D, with optional highlighting of slow-conduction
  intervals.

---

## `calcula_y_dibuja_VCG.m`

- **Source:** Internal wrapper of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Combines `idowerT` (12-lead -> VCG) with `cerrar_bucle` and
  plotting via `dibuja_VCG`.

---

## `cerrar_bucle.m`

- **Source:** Internal utility of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Closes the VCG loop by subtracting a linear correction between
  the first and last samples of each lead.

---

## `corr_VCG_SRC.m`

- **Source:** Internal utility of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Computes the rotation-invariant correlation between two VCG
  loops by iteratively rotating one of them and averaging the cosine of the
  angle between corresponding points.

---

## `resampleVCG_SRC.m`

- **Source:** Internal utility of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Resamples a VCG to a fixed number of points using periodic
  replication to minimise boundary artefacts.

---

## `normalizeVCG_Amplitude.m`

- **Source:** Internal utility of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Normalises the overall VCG amplitude by the mean Euclidean
  norm across samples.

---

## `consistence.m`

- **Source:** Internal utility of the EP Analytics Lab / ITACA / UPV group.
- **Purpose:** Computes how much variance of a set of stacked VCG loops is
  explained by the first three principal components (PCA-based consistency
  metric).

---

## Acknowledgement

We thank the EP Analytics Lab / ITACA group at the Universitat Politecnica de Valencia
for permission to bundle these utilities. Any individual reusing the code in
`src/external/` outside this repository must respect the original authors'
citation and licensing requirements listed above.
