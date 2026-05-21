function tabla_final = consolidate_features_to_excel(input_dir, output_xlsx)
% CONSOLIDATE_FEATURES_TO_EXCEL  Aggregate per-patient feature .mat files
%                                into a single Excel spreadsheet.
%
%   tabla_final = CONSOLIDATE_FEATURES_TO_EXCEL(input_dir, output_xlsx)
%   scans input_dir for files matching the pattern
%       resultado_total_<group>_paciente_<num>.mat
%   loads the struct stored in each one, converts it to a table row, and
%   adds three identification columns:
%       - ID       :  Original file name.
%       - grupo    :  Subtype tag extracted from the file name.
%       - paciente :  Numeric patient ID extracted from the file name.
%
%   All rows are concatenated into a single table and (optionally) written
%   to output_xlsx as an .xlsx file.
%
%   Inputs:
%     input_dir    --  Folder containing the resultado_total_*_paciente_*.mat
%                       files.
%     output_xlsx  --  (optional) Path of the output .xlsx file. If empty
%                       or omitted, no file is written.
%
%   Output:
%     tabla_final  --  Aggregated table.
%
% Original author: David Hernandez (UPV).

    if nargin < 2; output_xlsx = ''; end

    archivos = dir(fullfile(input_dir, 'resultado_total_*_paciente_*.mat'));
    tabla_final = table();

    for i = 1:numel(archivos)
        % Load the .mat file
        path_archivo = fullfile(input_dir, archivos(i).name);
        datos = load(path_archivo);

        % Struct stored in the .mat (first field)
        nombre_campo    = fieldnames(datos);
        struct_paciente = datos.(nombre_campo{1});

        % --- Extract group and patient number from the file name -------
        nombre = archivos(i).name;
        m = regexp(nombre, ...
                   '^resultado_total_(?<grupo>.+?)_paciente_(?<num>\d+)\.mat$', ...
                   'names');
        if isempty(m)
            warning('File name does not match the expected pattern: %s', nombre);
            continue
        end
        grupo = m.grupo;
        num_paciente = str2double(m.num);

        % --- Convert struct to single-row table and append IDs ---------
        t = struct2table(struct_paciente);   % 1 row, columns = fields
        t.ID       = string(nombre);
        t.grupo    = string(grupo);
        t.paciente = num_paciente;

        % Accumulate
        tabla_final = [tabla_final; t];   %#ok<AGROW>
    end

    disp(tabla_final)

    % --- Optional write to Excel ---------------------------------------
    if ~isempty(output_xlsx)
        writetable(tabla_final, output_xlsx);
        fprintf('Aggregated table written to: %s\n', output_xlsx);
    end

end
