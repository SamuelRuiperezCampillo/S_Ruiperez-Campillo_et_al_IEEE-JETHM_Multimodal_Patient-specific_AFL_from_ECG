function VCGaverage = load_vcg_by_type(tipo, vcg_dir, cycle_length, verbose)
% LOAD_VCG_BY_TYPE  Load every VCG file of a given flutter subtype.
%
%   VCGaverage = LOAD_VCG_BY_TYPE(tipo, vcg_dir) returns a 3-D tensor
%   stacking the VCG loops of every patient whose file matches the
%   provided subtype tag (e.g. '_C_CW', '_C_CCW', '_PM_CW', '_PM_CCW').
%   Each loop is zero-meaned and resampled to a common length.
%
%   VCGaverage = LOAD_VCG_BY_TYPE(tipo, vcg_dir, cycle_length, verbose)
%   lets the caller override the resampling target (default 500 samples)
%   and silence the per-file disp message (verbose = false, default true).
%
%   File-name convention: VCG_<id>_<group>_<direction>.txt
%
%   Inputs:
%     tipo          --  Subtype tag (string), e.g. '_C_CW'.
%     vcg_dir       --  Directory containing the VCG_*_*_*.txt files.
%     cycle_length  --  (optional) Resampling length in samples. Default 500.
%     verbose       --  (optional) Print the name of each loaded file.
%                        Default true.
%
%   Output:
%     VCGaverage    --  3 x cycle_length x N tensor with the N matched VCGs.
%
% Original author: David Hernandez (UPV).

    if nargin < 3 || isempty(cycle_length); cycle_length = 500;  end
    if nargin < 4 || isempty(verbose);      verbose      = true; end

    % --- Select files matching the subtype tag ---------------------------
    archivos = dir(fullfile(vcg_dir, 'VCG_*_*_*'));
    archivos_seleccionados = {};

    for i = 1:length(archivos)
        nombre_archivo = archivos(i).name;
        if contains(nombre_archivo, tipo)
            archivos_seleccionados{end+1} = fullfile(vcg_dir, nombre_archivo);
        end
    end

    % --- Load each matched file ------------------------------------------
    datos = {};
    for i = 1:length(archivos_seleccionados)
        archivo = archivos_seleccionados{i};
        datos{i} = readmatrix(archivo);
        if verbose
            disp(['File loaded: ', archivo]);
        end
    end

    % --- Stack the VCGs into a 3-D tensor --------------------------------
    VCG = struct();
    cyclelength = cycle_length;
    loopnumb = length(datos);   %#ok<NASGU>  preserved from original
    VCGall = [];
    for i = 1:length(datos)
        VCG.(sprintf('VCG_%d', i)) = datos{i}';
        VCG.(sprintf('VCG_%d', i));
        VCGall = zero_mean(VCG.(sprintf('VCG_%d', i)));
        VCGall = resampleVCG_SRC(VCGall, cyclelength);
        VCGaverage(:,:,i) = VCGall;
    end

end
