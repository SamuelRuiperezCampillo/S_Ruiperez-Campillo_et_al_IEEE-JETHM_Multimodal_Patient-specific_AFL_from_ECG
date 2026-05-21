% =========================================================================
%  01_preprocess_and_create_vcg.m
%
%  Top-level orchestration script: takes one raw 12-lead ECG file from disk
%  (identified by patient code), runs the full preprocessing pipeline to
%  obtain the averaged VCG loop, and saves the result as a text file.
%
%  The actual VCG construction logic lives in:
%     src/vcg/create_vcg_interactive.m
%
%  Pipeline overview (delegated to create_vcg_interactive):
%     1. High-pass + low-pass filtering of the ECG
%     2. Automatic F-wave selection (visual aid)
%     3. Manual selection (ginput) of the clean atrial segment
%     4. Inverse Dower transform (ECG -> VCG)
%     5. Cycle detection by autocorrelation
%     6. Per-cycle averaging + loop closure + zero-mean alignment
%
%  Inputs (set at the top of this script):
%     - ECG_DIR : folder containing the raw ECG files
%                 (expected naming: ECG_<id>_<group>_<direction>.txt)
%     - VCG_DIR : folder where the resulting VCG file will be written
%     - codigo  : numeric patient code identifying which ECG to process
%
%  Output:
%     A text file VCG_<codigo>.txt with the averaged VCG (transposed so
%     each row is one time sample and the three columns are X, Y, Z).
%
%  NOTE: patient data is NOT included in this repository. The user must
%  provide their own ECG files in ECG_DIR.
% =========================================================================

clear; clc; close all;

% --- USER CONFIGURATION ---------------------------------------------------
% Edit these paths to point to your local data folders.
ECG_DIR = fullfile(pwd, 'data', 'ECGs');         % input ECG folder
VCG_DIR = fullfile(pwd, 'data', 'VCGs');         % output VCG folder
codigo  = 80;                                     % patient code to process
fs      = 1000;                                   % sampling frequency (Hz)

% Make sure the repository source tree is on the MATLAB path.
addpath(genpath(fullfile(pwd, 'src')));

% Make sure the output folder exists.
if ~exist(VCG_DIR, 'dir'); mkdir(VCG_DIR); end

% --- 1. Locate the ECG file by patient code -------------------------------
codigo_str = ['_' num2str(codigo) '_'];
archivos   = dir(fullfile(ECG_DIR, 'ECG_*_*_*'));
ECG_file   = '';

for i = 1:length(archivos)
    nombre_archivo = archivos(i).name;
    if contains(nombre_archivo, codigo_str)
        ECG_file = fullfile(ECG_DIR, nombre_archivo);
        break;
    end
end

if ~isempty(ECG_file)
    disp(['Selected file: ', ECG_file]);
else
    error('No ECG file found for patient code %d.', codigo);
end

% --- 2. Load the raw ECG and transpose to the expected 12 x N layout -----
ECG = readmatrix(ECG_file);
ECG = transpose(ECG);

% --- 3. Run the full preprocessing + VCG-construction pipeline -----------
VCGMatrix = create_vcg_interactive(ECG, fs);

% --- 4. Save the resulting VCG to disk -----------------------------------
outputFile = fullfile(VCG_DIR, ['VCG_' num2str(codigo) '.txt']);
writematrix(VCGMatrix', outputFile);
disp(['VCG saved to: ', outputFile]);
