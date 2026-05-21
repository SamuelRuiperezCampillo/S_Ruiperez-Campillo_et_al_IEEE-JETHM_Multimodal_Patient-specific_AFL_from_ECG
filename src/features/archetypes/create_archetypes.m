function archetype = create_archetypes(VCGaverage, mode, k)
% CREATE_ARCHETYPES  Build a representative VCG archetype for one subtype.
%
%   archetype = CREATE_ARCHETYPES(VCGaverage, 'all') returns the archetype
%   built by averaging ALL the VCG loops contained in the input tensor.
%   This is the "production" archetype, intended to be saved and used as a
%   template for later correlation against new patients.
%
%   archetype = CREATE_ARCHETYPES(VCGaverage, 'kfold', k) runs a k-fold
%   robustness check: in each fold the archetype is built from the
%   training VCGs and is then correlated against the held-out test VCGs.
%   The function reports per-fold median / std and a global median / std
%   of those correlations, and plots the per-fold boxplots. The archetype
%   returned in this mode is the one built from the LAST fold (this matches
%   the original .mlx behaviour).
%
%   In both modes the VCG loop is closed with cerrar_bucle and the first
%   sample is appended at the end so that the loop starts and ends at the
%   same point (the same convention used everywhere else in the pipeline).
%
%   Inputs:
%     VCGaverage  --  3 x L x N tensor of N VCG loops of length L.
%     mode        --  'all' or 'kfold'.
%     k           --  (optional, only for 'kfold') number of folds.
%                      Default 3 (matches the original .mlx).
%
%   Output:
%     archetype   --  3 x (L+1) matrix with the archetype VCG loop, closed.
%
% Original author: David Hernandez (UPV).

    if nargin < 3 || isempty(k); k = 3; end

    switch lower(mode)
        case 'all'
            % --- Archetype built from ALL the VCGs --------------------
            archetype_raw = mean(VCGaverage, 3);

            % Close the VCG loop and append the first sample at the end
            VCG_2 = cerrar_bucle(archetype_raw);
            archetype = [VCG_2 VCG_2(:,1)];

            figure; dibuja_VCG(archetype, '2d', 'puntos')

        case 'kfold'
            % --- K-fold robustness check ------------------------------
            N = size(VCGaverage, 3);                % total number of VCGs

            cell_correlaciones = cell(1, k);
            cell_medianas      = cell(1, k);
            cell_std           = cell(1, k);

            cv = cvpartition(N, 'KFold', k);

            for fold = 1:k

                trainIdx = cv.training(fold);
                testIdx  = cv.test(fold);

                VCGtrain = VCGaverage(:,:,trainIdx);
                VCGtest  = VCGaverage(:,:,testIdx);

                fprintf('Fold %d: %d training samples, %d test samples\n', ...
                        fold, sum(trainIdx), sum(testIdx));

                % Archetype from this fold's training set
                archetype_raw = mean(VCGtrain, 3);
                VCG_2 = cerrar_bucle(archetype_raw);
                archetype = [VCG_2 VCG_2(:,1)];

                figure; dibuja_VCG(archetype, '2d', 'puntos')

                % Correlate each test VCG against the fold archetype
                for j = 1:size(VCGtest, 3)
                    alignedcorr = max(corr_VCG_SRC(VCGtest(:,:,j), archetype));
                    correlaciones(j) = alignedcorr;
                    fprintf('The correlation between these two VCGs is: %.2f \n\n', alignedcorr)
                end

                mediana    = median(correlaciones);
                desviacion = std(correlaciones);
                fprintf('The median is %.2f and std is %.2f \n\n', mediana, desviacion)

                cell_correlaciones{fold} = correlaciones;
                cell_medianas{fold}      = mediana;
                cell_std{fold}           = desviacion;
            end

            % Boxplots of per-fold correlations
            figure;
            tiledlayout(1, k);
            sgtitle('Boxplots of correlations per fold');

            % Global median and std across folds
            mean_median = cell2mat(cell_medianas);
            mean_median = mean(mean_median);
            mean_std    = cell2mat(cell_std);
            mean_std    = mean(mean_std);

            for i = 1:k
                nexttile;
                boxplot(cell_correlaciones{i});
                ylim([0 1]);
                title(['Fold ' num2str(i)]);
            end

            fprintf('Global median: %.2f Global std: %.2f', mean_median, mean_std)

        otherwise
            error('create_archetypes: mode must be ''all'' or ''kfold''.');
    end

end
