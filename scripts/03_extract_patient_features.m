% =========================================================================
%  03_extract_patient_features.m
%
%  Compute the full feature vector of one or more patients from their VCG.
%
%  Two operating modes (controlled by SINGLE_PATIENT_CODE):
%
%   MODE A (dataset preparation):
%     SINGLE_PATIENT_CODE = []   -> the script iterates over every patient
%     whose VCG is present in VCG_DIR and saves one feature file per
%     patient as resultado_total_<group>_paciente_<id>.mat in FEATURES_DIR.
%     The resulting .mat files are then aggregated into a spreadsheet by
%     04_consolidate_features.m.
%
%   MODE B (new-patient inference):
%     SINGLE_PATIENT_CODE = <integer>  -> the script processes only the
%     patient identified by that numeric code, prints / saves their
%     feature vector, and exits. The corresponding .mat can then be
%     appended to the master spreadsheet (or fed directly into a trained
%     classifier).
%
%  File-name convention expected in VCG_DIR:
%     VCG_<id>_<group>_<direction>.txt
%  where <group> is C or PM and <direction> is CW or CCW.
%
%  Group / direction are inferred from the file name and used to
%  determine which subtype the patient belongs to (so that
%  intergroup_correlation can leave-one-out the right group).
% =========================================================================

clear; clc; close all;

% --- USER CONFIGURATION ---------------------------------------------------
VCG_DIR             = fullfile(pwd, 'data', 'VCGs');          % input VCGs
FEATURES_DIR        = fullfile(pwd, 'data', 'features');      % output features
SINGLE_PATIENT_CODE = [];   % [] -> MODE A (all patients); <int> -> MODE B

% Add the source tree to the MATLAB path
addpath(genpath(fullfile(pwd, 'src')));

if ~exist(FEATURES_DIR, 'dir'); mkdir(FEATURES_DIR); end

% --- Locate the patient VCG files ----------------------------------------
archivos = dir(fullfile(VCG_DIR, 'VCG_*_*_*'));
if isempty(archivos)
    error('No VCG files found in %s.', VCG_DIR);
end

% Build a quick (id -> filename, subtype) lookup table from the file names
% Expected pattern: VCG_<id>_<group>_<direction>.txt
patient_info = struct('id',{},'group',{},'direction',{},'subtype',{},'fname',{});
for i = 1:numel(archivos)
    nm = archivos(i).name;
    m  = regexp(nm, '^VCG_(?<id>\d+)_(?<group>C|PM)_(?<dir>CW|CCW)', 'names');
    if isempty(m); continue; end
    patient_info(end+1).id        = str2double(m.id);
    patient_info(end).group       = m.group;
    patient_info(end).direction   = m.dir;
    patient_info(end).subtype     = ['_' m.group '_' m.dir];
    patient_info(end).fname       = nm;
end

if isempty(patient_info)
    error('No files in %s matched the expected naming convention.', VCG_DIR);
end

% --- Select which patients to process ------------------------------------
if isempty(SINGLE_PATIENT_CODE)
    fprintf('MODE A: processing %d patients...\n', numel(patient_info));
    to_process = patient_info;
else
    idx = find([patient_info.id] == SINGLE_PATIENT_CODE, 1);
    if isempty(idx)
        error('Patient code %d not found in %s.', SINGLE_PATIENT_CODE, VCG_DIR);
    end
    fprintf('MODE B: processing single patient %d\n', SINGLE_PATIENT_CODE);
    to_process = patient_info(idx);
end

% --- Main loop -----------------------------------------------------------
for p = 1:numel(to_process)
    pat = to_process(p);
    fprintf('\n--- Patient %d (subtype %s) ---\n', pat.id, pat.subtype);

    % Load the VCG of this patient (as a 3xL matrix)
    %
    % NOTE on patient index for intergroup_correlation:
    %   load_vcg_by_type returns a tensor 3xLxN sorted by the order in
    %   which the files are listed by dir(). We need the position of this
    %   patient WITHIN his subtype tensor (not the absolute patient id)
    %   because intergroup_correlation uses that position as its
    %   caso_analizar index. We recompute it here.
    archivos_subtype = dir(fullfile(VCG_DIR, ['VCG_*' pat.subtype '*']));
    idx_in_subtype = find(strcmp({archivos_subtype.name}, pat.fname), 1);
    if isempty(idx_in_subtype)
        warning('Could not place patient %d inside subtype tensor. Skipping.', pat.id);
        continue
    end

    % 1) Inter-group correlations (LOO inside own subtype)
    [~,~,~,~, vector_correlaciones] = ...
        intergroup_correlation(pat.subtype, VCG_DIR, idx_in_subtype);

    % 2) Load this patient's VCG explicitly (as a 3 x L matrix) so we can
    %    feed it to extract_patient_features.
    VCG_all_subtype = load_vcg_by_type(pat.subtype, VCG_DIR);
    VCG_analizar    = VCG_all_subtype(:,:,idx_in_subtype);

    % 3) Compute the full feature vector
    resultado_final = extract_patient_features(VCG_analizar, vector_correlaciones);

    % --- Save: resultado_total_<group>_paciente_<id>.mat ---
    clase = pat.subtype;
    clase = clase(2:end);    % strip leading underscore
    out_name = sprintf('resultado_total_%s_paciente_%d.mat', clase, pat.id);
    out_path = fullfile(FEATURES_DIR, out_name);
    save(out_path, 'resultado_final');
    fprintf('Saved features to: %s\n', out_path);
end

fprintf('\nDone.\n');
