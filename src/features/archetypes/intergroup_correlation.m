function [correlacion_grupo1, correlacion_grupo2, ...
          correlacion_grupo3, correlacion_grupo4, ...
          vector_correlaciones_caso_analizar] = ...
          intergroup_correlation(tipo, vcg_dir, caso_analizar)
% INTERGROUP_CORRELATION  Correlate every VCG of one subtype against the
%                         archetypes of the four flutter subtypes.
%
%   The function implements the same logic as the original four-branch
%   script (DavidH_correlacion_intergrupo), but factored to remove the
%   per-subtype code duplication. For the "self" subtype (the one matching
%   the input argument tipo), the archetype is recomputed in a
%   Leave-One-Out (LOO) loop so that the patient being tested is never
%   part of his own archetype. For the three "other" subtypes the
%   archetype is built once using all patients of that subtype.
%
%   Each VCG of the self subtype is then correlated, in the fixed order
%   C_CW, C_CCW, PM_CW, PM_CCW, against the four archetypes. If the
%   patient index of the LOO test fold matches caso_analizar, the four
%   correlations of that patient are printed and the group with the
%   maximum correlation is assigned via assign_group.
%
%   Inputs:
%     tipo          --  Self subtype tag: '_C_CW', '_C_CCW', '_PM_CW' or
%                        '_PM_CCW'.
%     vcg_dir       --  Folder with the VCG_*_*_*.txt files.
%     caso_analizar --  Patient index (within the self subtype) whose four
%                        correlations should be reported.
%
%   Outputs:
%     correlacion_grupo1..4              --  Row vectors with ALL the
%        correlations of the self-subtype VCGs against each of the four
%        archetypes (grupo1 = C_CW, grupo2 = C_CCW, grupo3 = PM_CW,
%        grupo4 = PM_CCW).
%     vector_correlaciones_caso_analizar --  1 x 4 vector with the four
%        correlations of the requested patient.
%
% Original author: David Hernandez (UPV).

    % --- Subtype tags in their canonical order ---------------------------
    tipos_ordenados = {'_C_CW', '_C_CCW', '_PM_CW', '_PM_CCW'};

    % --- Locate which of the four tags is the "self" --------------------
    tipo_str = char(tipo);
    self_idx = find(strcmp(tipos_ordenados, tipo_str), 1);
    if isempty(self_idx)
        error('intergroup_correlation: unknown subtype "%s".', tipo_str);
    end

    % --- Load the four subtype tensors in canonical order ---------------
    VCG_by_type = cell(1, 4);
    for t = 1:4
        VCG_by_type{t} = load_vcg_by_type(tipos_ordenados{t}, vcg_dir);
    end

    % --- Precompute the three non-self archetypes (mean + close loop) ---
    archetypes = cell(1, 4);
    for t = 1:4
        if t == self_idx
            continue   % the self archetype will be recomputed in LOO
        end
        arch_raw = mean(VCG_by_type{t}, 3);
        VCG_closed = cerrar_bucle(arch_raw);
        archetypes{t} = [VCG_closed VCG_closed(:,1)];
    end

    % --- LOO over the self subtype --------------------------------------
    VCG_self = VCG_by_type{self_idx};
    N = size(VCG_self, 3);
    fprintf('%d\n', N);                          % keep the original print

    cell_corr = cell(N, 4);
    cell_med  = cell(N, 4);
    cell_std  = cell(N, 4);

    cv = cvpartition(N, 'LeaveOut');

    % Initialise the requested-patient output in case caso_analizar > N
    vector_correlaciones_caso_analizar = nan(1, 4);

    for fold = 1:N
        trainIdx = cv.training(fold);
        testIdx  = cv.test(fold);
        VCG_escogido = find(testIdx);

        VCGtrain = VCG_self(:,:,trainIdx);
        VCGtest  = VCG_self(:,:,testIdx);

        fprintf('Fold %d: %d training samples, %d test samples\n', ...
                fold, sum(trainIdx), sum(testIdx));

        % Build the self archetype WITHOUT the held-out patient
        arch_self_raw  = mean(VCGtrain, 3);
        VCG_closed     = cerrar_bucle(arch_self_raw);
        archetypes{self_idx} = [VCG_closed VCG_closed(:,1)];

        % --- Correlate each test VCG against the four archetypes ------
        % Preallocate per-archetype correlation vectors for this fold
        % (here size(VCGtest,3) is 1 because LOO holds out a single patient,
        % but we keep the loop to mirror the original code 1:1).
        correlaciones   = zeros(1, size(VCGtest,3));
        correlaciones_2 = zeros(1, size(VCGtest,3));
        correlaciones_3 = zeros(1, size(VCGtest,3));
        correlaciones_4 = zeros(1, size(VCGtest,3));

        vector_correlaciones = zeros(1, 4);

        for j = 1:size(VCGtest, 3)
            alignedcorr  = max(corr_VCG_SRC(VCGtest(:,:,j), archetypes{1}));
            alignedcorr2 = max(corr_VCG_SRC(VCGtest(:,:,j), archetypes{2}));
            alignedcorr3 = max(corr_VCG_SRC(VCGtest(:,:,j), archetypes{3}));
            alignedcorr4 = max(corr_VCG_SRC(VCGtest(:,:,j), archetypes{4}));

            correlaciones(j)   = alignedcorr;
            correlaciones_2(j) = alignedcorr2;
            correlaciones_3(j) = alignedcorr3;
            correlaciones_4(j) = alignedcorr4;

            vector_correlaciones(1) = alignedcorr;
            vector_correlaciones(2) = alignedcorr2;
            vector_correlaciones(3) = alignedcorr3;
            vector_correlaciones(4) = alignedcorr4;

            if VCG_escogido == caso_analizar
                vector_correlaciones_caso_analizar = vector_correlaciones;
                fprintf('\n*** CORRELATIONS FOR CASE %d ***\n', caso_analizar);
                fprintf('C_CW:    %.3f\n', vector_correlaciones(1));
                fprintf('C_CCW:   %.3f\n', vector_correlaciones(2));
                fprintf('PM_CW:   %.3f\n', vector_correlaciones(3));
                fprintf('PM_CCW:  %.3f\n', vector_correlaciones(4));

                % Assign the test patient to the group of maximum correlation
                assign_group(VCGtest(:,:,j), tipo, vector_correlaciones)
                fprintf('Selected VCG number: %d\n', VCG_escogido)
            end
        end

        % Pack the four correlation vectors of this fold
        vecs = {correlaciones, correlaciones_2, correlaciones_3, correlaciones_4};
        for j = 1:4
            v = vecs{j};
            cell_corr{fold, j} = v;
            cell_med{fold, j}  = median(v);
            cell_std{fold, j}  = std(v);
        end
    end

    % --- Aggregate per-archetype correlations across folds --------------
    matrix_med = cell2mat(cell_med);
    matrix_std = cell2mat(cell_std);

    Media_global = mean(matrix_med, 1);    %#ok<NASGU>  preserved from original
    Media_std    = mean(matrix_std, 1);    %#ok<NASGU>

    correlacion_grupo1 = vertcat(cell_corr{:,1});
    correlacion_grupo1 = reshape(correlacion_grupo1, [1, numel(correlacion_grupo1)]);
    correlacion_grupo2 = vertcat(cell_corr{:,2});
    correlacion_grupo2 = reshape(correlacion_grupo2, [1, numel(correlacion_grupo2)]);
    correlacion_grupo3 = vertcat(cell_corr{:,3});
    correlacion_grupo3 = reshape(correlacion_grupo3, [1, numel(correlacion_grupo3)]);
    correlacion_grupo4 = vertcat(cell_corr{:,4});
    correlacion_grupo4 = reshape(correlacion_grupo4, [1, numel(correlacion_grupo4)]);

end
