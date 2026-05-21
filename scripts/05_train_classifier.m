% =========================================================================
%  05_train_classifier.m
%
%  Top-level orchestration script for the cascade classification stage.
%  Reads the consolidated feature spreadsheet, runs the nested K-fold
%  cross-validation pipeline (5 candidate models), and saves all
%  predictions, scores, ROC curves and confusion matrices.
%
%  Two modes (controlled by USE_CLINICAL_DATA):
%   - true  : the classifier uses VCG features + clinical variables
%             (age, BMI, CHA2DS2-VASc, LVEF, etc.). This is the
%             configuration reported in the paper.
%   - false : only VCG-derived features are used. Use this when the
%             clinical spreadsheet is not available.
%
%  If USE_CLINICAL_DATA = true, the input spreadsheet must already
%  contain the clinical columns merged in from the hospital data file.
%  This repository does NOT distribute the clinical data; you must
%  obtain it through the usual channels and merge it externally.
% =========================================================================

clear; clc; close all;

% --- USER CONFIGURATION ---------------------------------------------------
INPUT_XLSX        = fullfile(pwd, 'data', 'features_master.xlsx');
OUTPUT_MAT        = fullfile(pwd, 'models', 'classification_results.mat');
USE_CLINICAL_DATA = false;        % set to true if INPUT_XLSX already has the clinical columns merged in
K_OUTER           = 4;            % number of outer CV folds
RNG_SEED          = 42;           % for reproducibility

% Add the source tree to the MATLAB path
addpath(genpath(fullfile(pwd, 'src')));

% --- Load the feature table ----------------------------------------------
if ~exist(INPUT_XLSX, 'file')
    error('Feature spreadsheet not found: %s', INPUT_XLSX);
end
tabla = readtable(INPUT_XLSX);

% --- Run the cascade classification pipeline ------------------------------
[resultados, ROC_multiclase, ROC_binario, CM2, CM4] = ...
    cascade_classification_pipeline(tabla, USE_CLINICAL_DATA, K_OUTER, RNG_SEED);

% --- Persist all the outputs ---------------------------------------------
if ~exist(fileparts(OUTPUT_MAT), 'dir'); mkdir(fileparts(OUTPUT_MAT)); end
save(OUTPUT_MAT, 'resultados', 'ROC_multiclase', 'ROC_binario', 'CM2', 'CM4');
fprintf('\nAll results saved to: %s\n', OUTPUT_MAT);
