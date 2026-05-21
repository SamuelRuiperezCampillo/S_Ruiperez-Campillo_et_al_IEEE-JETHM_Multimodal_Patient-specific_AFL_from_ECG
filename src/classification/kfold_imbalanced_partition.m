function folds = kfold_imbalanced_partition(Y, K, modo)
% KFOLD_IMBALANCED_PARTITION  Class-stratified K-fold partition.
%
%   folds = KFOLD_IMBALANCED_PARTITION(Y, K, modo) returns a K x 2 cell
%   array where folds{k, 1} contains the training indices of the k-th
%   fold and folds{k, 2} the test indices. The partition is performed
%   class-by-class to guarantee that every class is represented in both
%   the training and the test side of every fold (i.e. it is stratified
%   over the imbalanced labels).
%
%   Inputs:
%     Y     --  Label vector (cell array of strings for multiclass mode,
%                or numeric / logical for binary mode).
%     K     --  Number of folds.
%     modo  --  'multiclase' (use Y as-is) or 'binario' (collapse
%                '_C_CW' and '_C_CCW' into one class C, and the rest
%                into PM).
%
%   Output:
%     folds  --  K x 2 cell array. Column 1 = training indices, column 2 =
%                test indices, both as column vectors.
%
% Original author: David Hernandez (UPV).

    if strcmp(modo, 'binario')
        fprintf('Binary mode: C vs PM\n');
        Y = ismember(Y, {'C_CW', 'C_CCW'});   % true = C, false = PM
        clases = [false; true];
    else
        fprintf('Multiclass mode\n');

        clases = unique(Y);
        if ~iscell(clases)
            clases = num2cell(clases);
        end
    end

    num_clases = numel(clases);
    folds = cell(K, 2);                         % {train_idx, test_idx}

    % Loop over classes (true/false or multiclass)
    for c = 1:num_clases
        if iscell(Y)   % multiclass case (string labels)
            idx_clase = find(strcmp(Y, clases{c}));
        else
            idx_clase = find(Y == clases(c));   % numeric or logical
        end

        cv_c = cvpartition(length(idx_clase), 'KFold', K);

        for k = 1:K
            if isempty(folds{k, 1})
                folds{k, 1} = idx_clase(training(cv_c, k));
                folds{k, 2} = idx_clase(test(cv_c, k));
            else
                folds{k, 1} = [folds{k, 1}; idx_clase(training(cv_c, k))];
                folds{k, 2} = [folds{k, 2}; idx_clase(test(cv_c, k))];
            end
        end
    end
end
