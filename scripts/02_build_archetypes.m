% =========================================================================
%  02_build_archetypes.m
%
%  Build one representative VCG archetype per flutter subtype.
%  For each of the four subtypes (_C_CW, _C_CCW, _PM_CW, _PM_CCW) this
%  script:
%     1. Loads every VCG of that subtype from VCG_DIR.
%     2. (Optional) Runs a K-fold robustness check by setting
%        ARCHETYPE_MODE = 'kfold'.
%     3. Builds the production archetype with mode = 'all' and saves it
%        to ARCHETYPE_DIR as VCG_<group>_AVG.txt.
%
%  The archetypes produced here are the templates against which every new
%  patient is correlated by intergroup_correlation.m. They are an input to
%  scripts 03 and 04.
% =========================================================================

clear; clc; close all;

% --- USER CONFIGURATION ---------------------------------------------------
VCG_DIR       = fullfile(pwd, 'data', 'VCGs');             % input VCGs
ARCHETYPE_DIR = fullfile(pwd, 'data', 'archetypes');       % output folder

% 'all'   -> single production archetype (saved to disk).
% 'kfold' -> K-fold robustness check; the production archetype is NOT
%            saved in this mode (results are reported via plots).
ARCHETYPE_MODE = 'all';
K_VAL          = 3;                                         % only used if 'kfold'

% Add the source tree to the MATLAB path
addpath(genpath(fullfile(pwd, 'src')));

if ~exist(ARCHETYPE_DIR, 'dir'); mkdir(ARCHETYPE_DIR); end

% --- Build one archetype per subtype -------------------------------------
subtypes = {'_C_CW', '_C_CCW', '_PM_CW', '_PM_CCW'};

for s = 1:numel(subtypes)
    tipo = subtypes{s};
    fprintf('\n========== Building archetype for %s ==========\n', tipo);

    % Load every VCG of this subtype
    VCGaverage = load_vcg_by_type(tipo, VCG_DIR);

    if isempty(VCGaverage)
        warning('No VCG files found for subtype %s. Skipping.', tipo);
        continue
    end

    % Build the archetype
    archetype = create_archetypes(VCGaverage, ARCHETYPE_MODE, K_VAL);

    % Save the production archetype (mode = 'all' only)
    if strcmp(ARCHETYPE_MODE, 'all')
        % Strip the leading underscore for the output filename
        tag = tipo(2:end);
        out_file = fullfile(ARCHETYPE_DIR, ['VCG_' tag '_AVG.txt']);
        writematrix(archetype', out_file);
        fprintf('Archetype saved to: %s\n', out_file);
    end
end

fprintf('\nDone.\n');
