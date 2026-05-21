function [resultados, ROC_multiclase, ROC_binario, CM2, CM4] = ...
         cascade_classification_pipeline(tabla, use_clinical_data, K, seed)
% CASCADE_CLASSIFICATION_PIPELINE  Nested K-fold CV with cascade reporting.
%
%   [resultados, ROC_multiclase, ROC_binario, CM2, CM4] = ...
%       CASCADE_CLASSIFICATION_PIPELINE(tabla, use_clinical_data, K, seed)
%   trains and evaluates the five candidate classifiers used in the paper
%   (Decision Tree, Bagged Trees / RF, AdaBoostM2, Logistic Penalised,
%   Linear SVM) on the feature table tabla, in a nested K-fold
%   cross-validation scheme:
%       - Outer  K-fold for unbiased performance estimation
%       - Inner  3-fold for hyperparameter tuning
%
%   Reporting is organised as a cascade:
%       BLOCK A  --  Substrate-level discrimination: C vs PM, with
%                    Clopper-Pearson exact 95% confidence intervals on
%                    Sens / Spec / F1.
%       BLOCK B  --  Within-substrate direction discrimination
%                    (CCW vs CW), restricted to the patients whose
%                    substrate was correctly predicted in Block A.
%                    The 0/0 blocks in the 4x4 confusion matrix are
%                    therefore structural (caused by the cascade filter,
%                    not by the model).
%
%   ROC curves and confusion matrices are reported for the Bag / Random
%   Forest model only, mirroring the original script.
%
%   Inputs:
%     tabla              --  MATLAB table with all the features (one row
%                             per patient) AND a column named 'grupo' with
%                             the four-class labels (C_CW, C_CCW, PM_CW,
%                             PM_CCW).
%     use_clinical_data  --  Boolean. If true, the feature set includes
%                             clinical variables (age, BMI, CHA2DS2-VASc,
%                             LVEF, etc.). If false, only VCG-derived
%                             features are used.
%     K                  --  (optional) Number of outer folds. Default 4.
%     seed               --  (optional) RNG seed for reproducibility.
%                             Default 42.
%
%   Outputs:
%     resultados      --  Struct with the raw predictions and scores of
%                          both validation (A) and outer-test (B) folds,
%                          for every model.
%     ROC_multiclase  --  Struct with one-vs-rest ROC curves (Bag only).
%     ROC_binario     --  Struct with C-vs-PM ROC (Bag only).
%     CM2             --  2 x 2 confusion matrix (Bag, C vs PM).
%     CM4             --  4 x 4 cascade confusion matrix (Bag).
%
% Original author: David Hernandez (UPV).

    if nargin < 3 || isempty(K);    K    = 4;  end
    if nargin < 4 || isempty(seed); seed = 42; end

    % =====================================================================
    %  FEATURE SELECTION (depends on the use_clinical_data flag)
    % =====================================================================
    clinical_vars = {
        'Sex'
        'age'
        'BMI'
        'HTN'
        'CHADSVASC'
        'LVEF'
        'NO_AF'
        'Paroxysmal_AF'
        'Persistent_AF'
     
    };

    vcg_vars = {
        'max_vector'
        'OCC_T'
        'peak_differences'
        'average_homogeneity'
        'AUC_v'
        'AUC_w'
        'mean_v'
        'mean_v_1stSeg'
        'mean_v_2stSeg'
        'mean_w'                     % angular velocity mean
        'mean_w_1stSeg'             % angular
        'mean_w_2stSeg'             % angular
        'complexity'
        'fastest_direction'
        'sign'
        'kurtosis'
        'Kurtosis_ang'
        'correlation_C_CW'
        'correlation_C_CCW'
        'correlation_PM_CW'
        'correlation_PM_CCW'
    };

    if use_clinical_data
        variables_seleccionadas = [clinical_vars; vcg_vars];
    else
        variables_seleccionadas = vcg_vars;
    end

    idx_binarias = ismember(variables_seleccionadas, {
        'genero_0_varon_1_mujer_'
        'HTA_no_0_Si_1_'
        'HFA_NO'
        'HFA_paroxistica'
        'HFA_persistente'
    });

    binari_norm  = false;
    X            = table2array(tabla(:, variables_seleccionadas));
    Y            = tabla.grupo;
    N_total      = length(Y);

    fprintf('Total patients: %d\n', N_total);
    fprintf('Class distribution:\n');
    clases_unicas = unique(Y);
    for c = 1:length(clases_unicas)
        fprintf('  %s: %d\n', clases_unicas{c}, sum(strcmp(Y, clases_unicas{c})));
    end

    rng(seed);
    modo     = 'multiclase';
    folds    = kfold_imbalanced_partition(Y, K, modo);
    alpha_CI = 0.05;

    % Coverage check
    all_test_idx = [];
    for f = 1:K; all_test_idx = [all_test_idx; folds{f,2}]; end
    assert(length(unique(all_test_idx)) == N_total, ...
        'ERROR: some patient does not appear exactly once in the outer test');
    fprintf('Outer-fold coverage check OK\n');

    orden_4   = {'C_CCW','C_CW','PM_CCW','PM_CW'};
    orden_2   = {'C','PM'};
    sustratos = {'C','PM'};   %#ok<NASGU>

    % --- Hyperparameter grids ---
    ciclos        = [50, 100, 150, 200];
    hojas         = [1, 5];
    splits        = [100, 200];
    C_values      = [0.01, 0.1, 1, 10];
    lambda_values = [0.0001, 0.001, 0.01, 0.1];
    reg_types     = {'lasso','ridge'};

    todos_modelos   = {'Tree','Bag','AdaBoostM2','LogisticPenalizada','LinearSVM'};
    nombres_display = {'DT','RF','Ada','Elastic Net','Linear SVM'};
    n_modelos       = length(todos_modelos);

    % ---------------------------------------------------------------------
    %  Containers for outer test (B) and inner validation (A)
    % ---------------------------------------------------------------------
    Y_true_B = cell(n_modelos,1);  Y_pred_B = cell(n_modelos,1);
    scores_B  = cell(n_modelos,1); classnames_B = cell(n_modelos,1);
    Y_true_A = cell(n_modelos,1);  Y_pred_A = cell(n_modelos,1);
    scores_A  = cell(n_modelos,1); classnames_A = cell(n_modelos,1);

    for m = 1:n_modelos
        Y_true_B{m} = {};  Y_pred_B{m} = {};
        scores_B{m} = [];  classnames_B{m} = {};
        Y_true_A{m} = {};  Y_pred_A{m} = {};
        scores_A{m} = [];  classnames_A{m} = {};
    end

    % =====================================================================
    %  NESTED K-FOLD CV
    % =====================================================================
    for outer = 1:K
        fprintf('\n===== OUTER FOLD %d/%d =====\n', outer, K);

        idx_train    = folds{outer,1};
        idx_test     = folds{outer,2};
        Y_train_base = Y(idx_train);
        Y_test_outer = Y(idx_test);
        clases_tr    = unique(Y_train_base);

        fprintf('  N train=%d, N test=%d\n', length(idx_train), length(idx_test));

        % Normalisation without imputation (for tree-based models)
        X_tr_base = X(idx_train,:);
        X_te_base = X(idx_test,:);
        media_tr  = mean(X_tr_base,1);
        std_tr    = std(X_tr_base,0,1);
        std_tr(std_tr==0) = 1;
        if ~binari_norm
            std_tr(idx_binarias)   = 1;
            media_tr(idx_binarias) = 0;
        end
        X_tr_n = (X_tr_base - media_tr) ./ std_tr;
        X_te_n = (X_te_base - media_tr) ./ std_tr;

        % Normalisation with imputation (for SVM / Logistic)
        X_tr_imp = X_tr_base;
        X_te_imp = X_te_base;
        med_imp  = median(X_tr_imp, 1, 'omitnan');
        for col = 1:size(X_tr_imp,2)
            X_tr_imp(isnan(X_tr_imp(:,col)),col) = med_imp(col);
            X_te_imp(isnan(X_te_imp(:,col)),col) = med_imp(col);
        end
        media_imp = mean(X_tr_imp,1);
        std_imp   = std(X_tr_imp,0,1);
        std_imp(std_imp==0) = 1;
        if ~binari_norm
            std_imp(idx_binarias)   = 1;
            media_imp(idx_binarias) = 0;
        end
        X_tr_imp = (X_tr_imp - media_imp) ./ std_imp;
        X_te_imp = (X_te_imp - media_imp) ./ std_imp;

        % Stratified inner folds
        K_inner     = 3;
        folds_inner = cell(K_inner, 2);
        for c = 1:numel(clases_tr)
            idx_cl = find(strcmp(Y_train_base, clases_tr{c}));
            cv_in  = cvpartition(length(idx_cl), 'KFold', K_inner);
            for k = 1:K_inner
                if isempty(folds_inner{k,1})
                    folds_inner{k,1} = idx_cl(training(cv_in,k));
                    folds_inner{k,2} = idx_cl(test(cv_in,k));
                else
                    folds_inner{k,1} = [folds_inner{k,1}; idx_cl(training(cv_in,k))];
                    folds_inner{k,2} = [folds_inner{k,2}; idx_cl(test(cv_in,k))];
                end
            end
        end

        % ================================================================
        %  MODELS 1-3: Tree, Bag, AdaBoostM2
        % ================================================================
        for m_idx = 1:3
            nm = todos_modelos{m_idx};
            fprintf('  [%s] outer=%d\n', nm, outer);

            errores = zeros(length(ciclos), length(hojas), length(splits));
            for i = 1:length(ciclos)
                for j = 1:length(hojas)
                    for s = 1:length(splits)
                        err_k = zeros(K_inner,1);
                        for k = 1:K_inner
                            X_in = X_tr_n(folds_inner{k,1},:);
                            Y_in = Y_train_base(folds_inner{k,1});
                            X_va = X_tr_n(folds_inner{k,2},:);
                            Y_va = Y_train_base(folds_inner{k,2});
                            if strcmp(nm,'Tree')
                                mdl_g = fitctree(X_in,Y_in, ...
                                    'MinLeafSize',hojas(j), ...
                                    'MaxNumSplits',splits(s), ...
                                    'SplitCriterion','deviance');
                            else
                                t_g = templateTree('MinLeafSize',hojas(j), ...
                                    'MaxNumSplits',splits(s), ...
                                    'SplitCriterion','deviance', ...
                                    'NumVariablesToSample','all');
                                counts_g = zeros(1,numel(clases_tr));
                                for cc=1:numel(clases_tr)
                                    counts_g(cc)=sum(strcmp(Y_in,clases_tr{cc}));
                                end
                                w_g = N_total./(2*numel(clases_tr)*counts_g);
                                iw  = zeros(size(Y_in));
                                for cc=1:numel(clases_tr)
                                    iw(strcmp(Y_in,clases_tr{cc}))=w_g(cc);
                                end
                                mdl_g = fitcensemble(X_in,Y_in,'Method',nm, ...
                                    'NumLearningCycles',ciclos(i), ...
                                    'Learners',t_g,'Weights',iw);
                            end
                            Yp = predict(mdl_g,X_va);
                            err_k(k) = mean(~strcmp(Yp,Y_va));
                        end
                        errores(i,j,s) = mean(err_k);
                    end
                end
            end
            [~,idx_b]   = min(errores(:));
            [bi,bj,bs]  = ind2sub(size(errores),idx_b);
            best_ciclos = ciclos(bi);
            best_hojas  = hojas(bj);
            best_splits = splits(bs);

            % Inner validation with best hyperparameters (PART A)
            for k = 1:K_inner
                X_in = X_tr_n(folds_inner{k,1},:);
                Y_in = Y_train_base(folds_inner{k,1});
                X_va = X_tr_n(folds_inner{k,2},:);
                Y_va = Y_train_base(folds_inner{k,2});
                if strcmp(nm,'Tree')
                    mdl_A = fitctree(X_in,Y_in, ...
                        'MinLeafSize',best_hojas, ...
                        'MaxNumSplits',best_splits, ...
                        'SplitCriterion','deviance');
                else
                    t_A = templateTree('MinLeafSize',best_hojas, ...
                        'MaxNumSplits',best_splits, ...
                        'SplitCriterion','deviance', ...
                        'NumVariablesToSample','all');
                    mdl_A = fitcensemble(X_in,Y_in,'Method',nm, ...
                        'NumLearningCycles',best_ciclos,'Learners',t_A);
                end
                [Yp_A, sc_A]    = predict(mdl_A, X_va);
                Y_true_A{m_idx} = [Y_true_A{m_idx}; Y_va];
                Y_pred_A{m_idx} = [Y_pred_A{m_idx}; Yp_A];
                scores_A{m_idx} = [scores_A{m_idx}; sc_A];
                classnames_A{m_idx} = mdl_A.ClassNames;
            end

            % Final model on outer test (PART B)
            rng(seed + outer + m_idx);
            if strcmp(nm,'Tree')
                mdl_f = fitctree(X_tr_n,Y_train_base, ...
                    'MinLeafSize',best_hojas, ...
                    'MaxNumSplits',best_splits, ...
                    'SplitCriterion','deviance');
            else
                t_f = templateTree('MinLeafSize',best_hojas, ...
                    'MaxNumSplits',best_splits, ...
                    'SplitCriterion','deviance', ...
                    'NumVariablesToSample','all');
                mdl_f = fitcensemble(X_tr_n,Y_train_base,'Method',nm, ...
                    'NumLearningCycles',best_ciclos,'Learners',t_f);
            end
            [Yp_B, sc_B]     = predict(mdl_f, X_te_n);
            Y_true_B{m_idx}  = [Y_true_B{m_idx};  Y_test_outer];
            Y_pred_B{m_idx}  = [Y_pred_B{m_idx};  Yp_B];
            scores_B{m_idx}  = [scores_B{m_idx};  sc_B];
            classnames_B{m_idx} = mdl_f.ClassNames;
        end

        % ================================================================
        %  MODEL 4: Penalised logistic regression (Elastic Net)
        % ================================================================
        m_idx = 4;
        fprintf('  [LogisticPenalizada] outer=%d\n', outer);
        errores_en = zeros(length(reg_types), length(lambda_values), K_inner);
        for r = 1:length(reg_types)
            for i = 1:length(lambda_values)
                for k = 1:K_inner
                    X_in = X_tr_imp(folds_inner{k,1},:);
                    Y_in = Y_train_base(folds_inner{k,1});
                    X_va = X_tr_imp(folds_inner{k,2},:);
                    Y_va = Y_train_base(folds_inner{k,2});
                    t_en = templateLinear('Learner','logistic', ...
                        'Regularization',reg_types{r},'Lambda',lambda_values(i));
                    mdl_g = fitcecoc(X_in,Y_in,'Learners',t_en,'Coding','onevsone');
                    Yp    = predict(mdl_g, X_va);
                    errores_en(r,i,k) = mean(~strcmp(Yp,Y_va));
                end
            end
        end
        err_med    = mean(errores_en,3);
        [~,b_en]   = min(err_med(:));
        [br,bi_en] = ind2sub(size(err_med),b_en);
        best_reg   = reg_types{br};
        best_lam   = lambda_values(bi_en);

        for k = 1:K_inner
            X_in  = X_tr_imp(folds_inner{k,1},:);
            Y_in  = Y_train_base(folds_inner{k,1});
            X_va  = X_tr_imp(folds_inner{k,2},:);
            Y_va  = Y_train_base(folds_inner{k,2});
            t_A   = templateLinear('Learner','logistic', ...
                'Regularization',best_reg,'Lambda',best_lam);
            mdl_A = fitcecoc(X_in,Y_in,'Learners',t_A, ...
                'Coding','onevsone','FitPosterior',true);
            [Yp_A, sc_A]    = predict(mdl_A, X_va);
            Y_true_A{m_idx} = [Y_true_A{m_idx}; Y_va];
            Y_pred_A{m_idx} = [Y_pred_A{m_idx}; Yp_A];
            scores_A{m_idx} = [scores_A{m_idx}; sc_A];
            classnames_A{m_idx} = mdl_A.ClassNames;
        end

        rng(seed + outer + 20);
        t_f   = templateLinear('Learner','logistic', ...
            'Regularization',best_reg,'Lambda',best_lam);
        mdl_f = fitcecoc(X_tr_imp,Y_train_base,'Learners',t_f, ...
            'Coding','onevsone','FitPosterior',true);
        [Yp_B, sc_B]     = predict(mdl_f, X_te_imp);
        Y_true_B{m_idx}  = [Y_true_B{m_idx};  Y_test_outer];
        Y_pred_B{m_idx}  = [Y_pred_B{m_idx};  Yp_B];
        scores_B{m_idx}  = [scores_B{m_idx};  sc_B];
        classnames_B{m_idx} = mdl_f.ClassNames;

        % ================================================================
        %  MODEL 5: Linear SVM
        % ================================================================
        m_idx = 5;
        fprintf('  [LinearSVM] outer=%d\n', outer);
        errores_svm = zeros(length(C_values), K_inner);
        for i = 1:length(C_values)
            for k = 1:K_inner
                X_in  = X_tr_imp(folds_inner{k,1},:);
                Y_in  = Y_train_base(folds_inner{k,1});
                X_va  = X_tr_imp(folds_inner{k,2},:);
                Y_va  = Y_train_base(folds_inner{k,2});
                t_sv  = templateSVM('KernelFunction','linear', ...
                    'BoxConstraint',C_values(i),'Standardize',true);
                mdl_g = fitcecoc(X_in,Y_in,'Learners',t_sv,'Coding','onevsone');
                Yp    = predict(mdl_g, X_va);
                errores_svm(i,k) = mean(~strcmp(Yp,Y_va));
            end
        end
        [~,b_sv] = min(mean(errores_svm,2));
        best_C   = C_values(b_sv);

        for k = 1:K_inner
            X_in  = X_tr_imp(folds_inner{k,1},:);
            Y_in  = Y_train_base(folds_inner{k,1});
            X_va  = X_tr_imp(folds_inner{k,2},:);
            Y_va  = Y_train_base(folds_inner{k,2});
            t_A   = templateSVM('KernelFunction','linear', ...
                'BoxConstraint',best_C,'Standardize',true);
            mdl_A = fitcecoc(X_in,Y_in,'Learners',t_A, ...
                'Coding','onevsone','FitPosterior',true);
            [Yp_A, sc_A]    = predict(mdl_A, X_va);
            Y_true_A{m_idx} = [Y_true_A{m_idx}; Y_va];
            Y_pred_A{m_idx} = [Y_pred_A{m_idx}; Yp_A];
            scores_A{m_idx} = [scores_A{m_idx}; sc_A];
            classnames_A{m_idx} = mdl_A.ClassNames;
        end

        rng(seed + outer + 10);
        t_f   = templateSVM('KernelFunction','linear', ...
            'BoxConstraint',best_C,'Standardize',true);
        mdl_f = fitcecoc(X_tr_imp,Y_train_base,'Learners',t_f, ...
            'Coding','onevsone','FitPosterior',true);
        [Yp_B, sc_B]     = predict(mdl_f, X_te_imp);
        Y_true_B{m_idx}  = [Y_true_B{m_idx};  Y_test_outer];
        Y_pred_B{m_idx}  = [Y_pred_B{m_idx};  Yp_B];
        scores_B{m_idx}  = [scores_B{m_idx};  sc_B];
        classnames_B{m_idx} = mdl_f.ClassNames;

    end  % outer folds

    % Verification
    fprintf('\n--- Outer-test counts verification ---\n');
    for m = 1:n_modelos
        assert(length(Y_true_B{m}) == N_total, ...
            'ERROR: %s has %d predictions, expected %d', ...
            todos_modelos{m}, length(Y_true_B{m}), N_total);
        fprintf('  %s: OK (%d)\n', todos_modelos{m}, length(Y_true_B{m}));
    end

    % =====================================================================
    %  REPORTING TABLES: internal (A) and external (B)
    % =====================================================================
    for parte = {'A','B'}
        parte = parte{1};

        if strcmp(parte,'A')
            Y_true_p = Y_true_A;
            Y_pred_p = Y_pred_A;
            sc_p     = scores_A;   %#ok<NASGU>
            cn_p     = classnames_A;   %#ok<NASGU>
            titulo   = 'INTERNAL VALIDATION (inner folds)';
            nota     = '(each patient appears several times)';
        else
            Y_true_p = Y_true_B;
            Y_pred_p = Y_pred_B;
            sc_p     = scores_B;   %#ok<NASGU>
            cn_p     = classnames_B;   %#ok<NASGU>
            titulo   = 'EXTERNAL OUTER-TEST';
            nota     = '(each patient exactly once)';
        end

        fprintf('\n%s\n', repmat('=',1,120));
        fprintf('%s  --  %s\n%s\n', titulo, nota, repmat('-',1,120));

        metricas = {'Sens','Spec','F1'};

        % ----------------------------------------------------------------
        %  BLOCK A: C vs PM
        % ----------------------------------------------------------------
        fprintf('\n--- BLOCK A: Substrate-level discrimination (C vs PM) ---\n');
        fprintf('%-10s %-16s | %-38s | %-38s\n', ...
            'Metric','Model','C (aggregated)','PM (aggregated)');
        fprintf('%s\n', repmat('-',1,110));

        for met_idx = 1:length(metricas)
            met = metricas{met_idx};
            for m_idx = 1:n_modelos

                Yt = Y_true_p{m_idx};
                Yp = Y_pred_p{m_idx};

                % Collapse to substrate labels
                Yt2  = cellfun(@(x) regexprep(x,'_(CCW|CW)$',''), Yt, 'UniformOutput',false);
                Yp2  = cellfun(@(x) regexprep(x,'_(CCW|CW)$',''), Yp, 'UniformOutput',false);

                cel = cell(1,2);
                for ci = 1:2
                    cl2 = orden_2{ci};
                    if strcmp(met,'AUROC')
                        cel{ci} = 'TBF';   % AUROC placeholder
                    else
                        Yb2  = strcmp(Yt2, cl2);
                        Yp2b = strcmp(Yp2, cl2);
                        TP = sum( Yb2 &  Yp2b);
                        FP = sum(~Yb2 &  Yp2b);
                        TN = sum(~Yb2 & ~Yp2b);
                        FN = sum( Yb2 & ~Yp2b);
                        switch met
                            case 'Sens', cel{ci} = cp_fmt(TP,    TP+FN,       alpha_CI);
                            case 'Spec', cel{ci} = cp_fmt(TN,    TN+FP,       alpha_CI);
                            case 'F1',   cel{ci} = cp_fmt(2*TP,  2*TP+FP+FN,  alpha_CI);
                        end
                    end
                end

                lbl = ''; if m_idx==1; lbl = met; end
                fprintf('%-10s %-16s | %-38s | %-38s\n', ...
                    lbl, nombres_display{m_idx}, cel{1}, cel{2});
            end
            fprintf('%s\n', repmat('-',1,110));
        end

        % ----------------------------------------------------------------
        %  BLOCK B: 4-class with cascade filter (Sens/Spec/F1 only)
        % ----------------------------------------------------------------
        if ~strcmp(met,'AUROC')
            fprintf('\n--- BLOCK B: Within-substrate conduction discrimination ---\n');
            fprintf('    Cascade filter: only patients whose substrate was correctly predicted\n');
            fprintf('%-10s %-16s | %-30s %-30s | %-30s %-30s\n', ...
                'Metric','Model','C_CCW','C_CW','PM_CCW','PM_CW');
            fprintf('%s\n', repmat('-',1,125));

            for met_idx = 1:3
                met = metricas{met_idx};
                for m_idx = 1:n_modelos

                    Yt = Y_true_p{m_idx};
                    Yp = Y_pred_p{m_idx};

                    % Collapse to substrate for the filter
                    Yt_sust = cellfun(@(x) regexprep(x,'_(CCW|CW)$',''), Yt, 'UniformOutput',false);
                    Yp_sust = cellfun(@(x) regexprep(x,'_(CCW|CW)$',''), Yp, 'UniformOutput',false);

                    cel = cell(1,4);
                    for ci = 1:4
                        cl4 = orden_4{ci};

                        % Substrate of this class
                        if contains(cl4,'C_')
                            sust = 'C';
                        else
                            sust = 'PM';
                        end

                        % CASCADE FILTER: patients whose substrate was
                        % correctly predicted
                        idx_filt = strcmp(Yt_sust, sust) & strcmp(Yp_sust, sust);
                        N_sub    = sum(idx_filt);

                        if N_sub < 3
                            cel{ci} = sprintf('N/A (n=%d)', N_sub);
                            continue
                        end

                        % Filtered subset
                        Yt_sub = Yt(idx_filt);
                        Yp_sub = Yp(idx_filt);

                        % One-vs-rest within the filtered subset
                        Yb_sub   = strcmp(Yt_sub, cl4);
                        Yp_sub_b = strcmp(Yp_sub, cl4);

                        TP = sum( Yb_sub &  Yp_sub_b);
                        FP = sum(~Yb_sub &  Yp_sub_b);
                        TN = sum(~Yb_sub & ~Yp_sub_b);
                        FN = sum( Yb_sub & ~Yp_sub_b);

                        switch met
                            case 'Sens', cel{ci} = cp_fmt(TP,   TP+FN,      alpha_CI);
                            case 'Spec', cel{ci} = cp_fmt(TN,   TN+FP,      alpha_CI);
                            case 'F1',   cel{ci} = cp_fmt(2*TP, 2*TP+FP+FN, alpha_CI);
                        end
                    end

                    lbl = ''; if m_idx==1; lbl = met; end
                    fprintf('%-10s %-16s | %-30s %-30s | %-30s %-30s\n', ...
                        lbl, nombres_display{m_idx}, cel{1}, cel{2}, cel{3}, cel{4});
                end
                fprintf('%s\n', repmat('-',1,125));
            end
        end

        fprintf('%s\n\n', repmat('=',1,120));
    end

    % =====================================================================
    %  ROC CURVES -- BAG MODEL (m_idx = 2)
    % =====================================================================
    m_bag = 2;

    % --- ROC multiclass: one-vs-rest, 4 classes (outer test, Block B) ---
    Yt_mc  = Y_true_B{m_bag};
    Yp_mc  = Y_pred_B{m_bag};   %#ok<NASGU>
    sc_mc  = scores_B{m_bag};
    cn_mc  = classnames_B{m_bag};

    ROC_multiclase = struct();

    figure('Name','ROC Multiclass - Bag (outer test)','NumberTitle','off');
    hold on;
    colors_mc  = lines(length(orden_4));
    legend_mc  = strings(length(orden_4), 1);

    for ci = 1:length(orden_4)
        clase_actual = orden_4{ci};
        Y_bin_mc     = strcmp(Yt_mc, clase_actual);
        clase_idx_mc = find(strcmp(cn_mc, clase_actual));
        scores_cl    = sc_mc(:, clase_idx_mc);

        [Xroc, Yroc, ~, AUC] = perfcurve(Y_bin_mc, scores_cl, 1);

        ROC_multiclase.(clase_actual).Xroc = Xroc;
        ROC_multiclase.(clase_actual).Yroc = Yroc;
        ROC_multiclase.(clase_actual).AUC  = AUC;

        plot(Xroc, Yroc, 'LineWidth', 2, 'Color', colors_mc(ci,:));
        legend_mc(ci) = sprintf('%s (AUC = %.2f)', clase_actual, AUC);
    end

    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title('ROC Multiclass - Bag (outer test, one-vs-rest)');
    legend(legend_mc, 'Location', 'SouthEast');
    grid on;
    hold off;

    % --- ROC binary: C vs PM collapsed (outer test, Block A) -------------
    Yt_bin = Y_true_B{m_bag};
    sc_bin = scores_B{m_bag};
    cn_bin = classnames_B{m_bag};

    Yt_col = cellfun(@(x) regexprep(x, '_(CCW|CW)$', ''), Yt_bin, 'UniformOutput', false);

    idx_C_CCW = find(strcmp(cn_bin, 'C_CCW'));
    idx_C_CW  = find(strcmp(cn_bin, 'C_CW'));
    score_C   = sc_bin(:, idx_C_CCW) + sc_bin(:, idx_C_CW);

    Y_bin_roc = strcmp(Yt_col, 'C');

    [Xroc_bin, Yroc_bin, ~, AUC_bin] = perfcurve(Y_bin_roc, score_C, 1);

    ROC_binario.Xroc = Xroc_bin;
    ROC_binario.Yroc = Yroc_bin;
    ROC_binario.AUC  = AUC_bin;

    figure('Name','ROC Binary C vs PM - Bag (outer test)','NumberTitle','off');
    plot(Xroc_bin, Yroc_bin, 'LineWidth', 2, 'Color', [0 0.45 0.74]);
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title(sprintf('ROC Binary C vs PM - Bag (outer test) | AUC = %.2f', AUC_bin));
    grid on;

    % =====================================================================
    %  CONFUSION MATRICES -- RANDOM FOREST (Bag, m_idx = 2)
    %
    %  Figure 1: 2x2 -- C vs PM (all patients, outer test).
    %  Figure 2: 4x4 -- cascade (only patients passing the substrate
    %                   filter). The structural zeros reflect the filter,
    %                   not the model. a+b+c+d == X_CC, e+f+g+h == X_PMPM
    %                   from the 2x2 matrix above.
    % =====================================================================
    m_rf = 2;

    Yt_rf = Y_true_B{m_rf};
    Yp_rf = Y_pred_B{m_rf};

    % --- 2x2 confusion matrix (C vs PM) --------------------------------
    Yt_sust_rf = cellfun(@(x) regexprep(x,'_(CCW|CW)$',''), Yt_rf, 'UniformOutput',false);
    Yp_sust_rf = cellfun(@(x) regexprep(x,'_(CCW|CW)$',''), Yp_rf, 'UniformOutput',false);

    CM2 = zeros(2,2);
    for ri = 1:2
        for ci = 1:2
            CM2(ri,ci) = sum(strcmp(Yt_sust_rf, orden_2{ri}) & ...
                             strcmp(Yp_sust_rf, orden_2{ci}));
        end
    end

    fprintf('\n%s\n', repmat('=',1,60));
    fprintf('CONFUSION MATRIX 2x2 -- RF -- C vs PM (outer test, N=%d)\n', N_total);
    fprintf('%s\n', repmat('-',1,60));
    fprintf('%-12s | %-10s %-10s\n','Real \\ Pred', orden_2{1}, orden_2{2});
    fprintf('%s\n', repmat('-',1,36));
    for ri = 1:2
        fprintf('%-12s | %-10d %-10d\n', orden_2{ri}, CM2(ri,1), CM2(ri,2));
    end
    fprintf('%s\n', repmat('=',1,60));
    fprintf('Verification: sum(CM2) = %d (expected %d)\n', sum(CM2(:)), N_total);

    figure('Name','CM 2x2 - RF - C vs PM','NumberTitle','off');
    imagesc(CM2);
    colormap(flipud(bone));
    colorbar;
    title('RF -- Confusion Matrix: C vs PM (outer test)','FontSize',13);
    xlabel('Predicted label','FontSize',11);
    ylabel('True label','FontSize',11);
    xticks(1:2); xticklabels(orden_2);
    yticks(1:2); yticklabels(orden_2);
    for ri = 1:2
        for ci = 1:2
            text(ci, ri, num2str(CM2(ri,ci)), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',14,'FontWeight','bold', ...
                'Color', 'red');
        end
    end

    % --- 4x4 confusion matrix (cascade) --------------------------------
    % Off-diagonal substrate blocks are 0 BY CONSTRUCTION of the cascade
    % filter (a patient predicted as the wrong substrate is excluded
    % from Block B). This is the intended behaviour and is also why the
    % matrix is consistent with the 2x2 matrix above
    % (sum(C-block) = CM2(1,1), sum(PM-block) = CM2(2,2)).
    CM4 = zeros(4,4);
    for ri = 1:4
        cl_real = orden_4{ri};
        if contains(cl_real,'C_'); sust_real = 'C'; else; sust_real = 'PM'; end

        for ci = 1:4
            cl_pred = orden_4{ci};
            if contains(cl_pred,'C_'); sust_pred = 'C'; else; sust_pred = 'PM'; end

            % Only count if both substrates match (cascade filter)
            if strcmp(sust_real, sust_pred)
                CM4(ri,ci) = sum(strcmp(Yt_rf, cl_real) & strcmp(Yp_rf, cl_pred));
            end
        end
    end

    fprintf('\n%s\n', repmat('=',1,70));
    fprintf('CONFUSION MATRIX 4x4 -- RF -- cascade (outer test)\n');
    fprintf('Structural zeros = patients excluded by the substrate filter\n');
    fprintf('%s\n', repmat('-',1,70));
    fprintf('%-12s | %-10s %-10s %-10s %-10s\n','Real \\ Pred', orden_4{:});
    fprintf('%s\n', repmat('-',1,55));
    for ri = 1:4
        fprintf('%-12s | %-10d %-10d %-10d %-10d\n', ...
            orden_4{ri}, CM4(ri,1), CM4(ri,2), CM4(ri,3), CM4(ri,4));
    end
    fprintf('%s\n', repmat('=',1,70));

    % Consistency check between CM2 and CM4
    fprintf('Consistency check CM2 <-> CM4:\n');
    fprintf('  CM2(C,C)   = %d  ==  sum(CM4 C block)   = %d  -> %s\n', ...
        CM2(1,1), sum(sum(CM4(1:2,1:2))), iif(CM2(1,1)==sum(sum(CM4(1:2,1:2))),'OK','ERROR'));
    fprintf('  CM2(PM,PM) = %d  ==  sum(CM4 PM block)  = %d  -> %s\n', ...
        CM2(2,2), sum(sum(CM4(3:4,3:4))), iif(CM2(2,2)==sum(sum(CM4(3:4,3:4))),'OK','ERROR'));

    etiq4 = {'C\_CCW','C\_CW','PM\_CCW','PM\_CW'};
    figure('Name','CM 4x4 - RF - cascade','NumberTitle','off');
    imagesc(CM4);
    colormap(flipud(bone));
    colorbar;
    title('RF -- Confusion Matrix 4x4: cascade (outer test)','FontSize',13);
    xlabel('Predicted label','FontSize',11);
    ylabel('True label','FontSize',11);
    xticks(1:4); xticklabels(etiq4);
    yticks(1:4); yticklabels(etiq4);
    hold on;
    plot([2.5 2.5],[0.5 4.5],'r--','LineWidth',1.5);
    plot([0.5 4.5],[2.5 2.5],'r--','LineWidth',1.5);
    hold off;
    for ri = 1:4
        for ci = 1:4
            text(ci, ri, num2str(CM4(ri,ci)), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',13,'FontWeight','bold', ...
                'Color','red');
        end
    end

    % --- Pack everything for the caller ---------------------------------
    resultados = struct( ...
        'Y_true_B', {Y_true_B}, ...
        'Y_pred_B', {Y_pred_B}, ...
        'scores_B', {scores_B}, ...
        'classnames_B', {classnames_B}, ...
        'Y_true_A', {Y_true_A}, ...
        'Y_pred_A', {Y_pred_A}, ...
        'scores_A', {scores_A}, ...
        'classnames_A', {classnames_A}, ...
        'orden_4', {orden_4}, ...
        'orden_2', {orden_2}, ...
        'todos_modelos', {todos_modelos}, ...
        'nombres_display', {nombres_display}, ...
        'N_total', N_total);

end

% =========================================================================
%  Local helper functions
% =========================================================================
function s = cp_fmt(k, n, alpha)
    % CP_FMT -- Clopper-Pearson exact CI plus formatted string.
    if n == 0
        s = 'N/A'; return
    end
    if k == 0
        lo = 0;
    else
        lo = betainv(alpha/2, k, n-k+1);
    end
    if k == n
        hi = 1;
    else
        hi = betainv(1-alpha/2, k+1, n-k);
    end
    s = sprintf('%.2f [%.2f, %.2f] (n=%d)', k/n, lo, hi, n);
end

function s = iif(cond, a, b)
    if cond; s = a; else; s = b; end
end
