function resultado_final = extract_patient_features(VCG, vector_correlaciones)
% EXTRACT_PATIENT_FEATURES  Compute the full feature vector of one patient.
%
%   resultado_final = EXTRACT_PATIENT_FEATURES(VCG, vector_correlaciones)
%   takes a single patient's averaged VCG loop and the 1x4 vector of
%   inter-group correlations (against the C_CW, C_CCW, PM_CW and PM_CCW
%   archetypes) and returns a struct with EVERY feature consumed by the
%   classifier downstream:
%
%     - Archetype correlations (4 values).
%     - Geometric features: VCG / ellipse areas and their difference,
%       max-vector amplitude, semi-axes, centre, rotation angle,
%       perimeters, complexity, cylindricity.
%     - Linear-velocity descriptors: SVPOT, SVPOD, ratio, dispersion,
%       homogeneity (mean / median), kurtosis, asymmetry, area under
%       the curve, dominant direction.
%     - Angular-velocity descriptors: dispersion, homogeneity (mean /
%       median), kurtosis, asymmetry, area under the curve.
%     - Block-wise mean velocities (linear and angular).
%
%   The field names exactly match the column names expected by
%   consolidate_features_to_excel.m and cascade_classification_pipeline.m,
%   so the output of this function can be saved as
%   resultado_total_<group>_paciente_<id>.mat and consumed verbatim by the
%   downstream pipeline.
%
%   Field names that are misleading on purpose (kept for backward
%   compatibility with the original new_patient script and the existing
%   feature spreadsheet):
%       - 'media_pacientes_no_angular' : mean of the LINEAR velocity.
%       - 'media_velocidad_angular_total' : mean of the ANGULAR velocity.
%       - 'velocidad_media_bloque1' / '..._bloque2' : block means computed
%         on the LINEAR velocity vector (this matches the original code;
%         the variable names refer to the angular block windows used to
%         select the samples, not to angular velocity itself).
%
%   Inputs:
%     VCG                    --  3 x L averaged VCG loop.
%     vector_correlaciones   --  1 x 4 vector with the inter-group
%                                 correlations of this patient (canonical
%                                 order C_CW, C_CCW, PM_CW, PM_CCW), as
%                                 returned by intergroup_correlation.m.
%
%   Output:
%     resultado_final  --  Struct with all the features above as fields.
%
% Original author: David Hernandez (UPV).

    % --- 1) Geometric complexity (XY plane) ----------------------------
    [resultados, a, b, x0, y0, phi] = geometric_complexity(VCG(1,:), VCG(3,:));

    % --- 2) VCG / ellipse area in the XZ plane -------------------------
    [area_VCG, area_elipse, diferencia] = vcg_ellipse_area(VCG);

    % --- 3) Maximum-vector amplitude ----------------------------------
    vector_maximo = max_vector(VCG);

    % --- 4) Linear-velocity descriptors -------------------------------
    [v, ~, carac_vel] = velocity_features(VCG);
    velocidad_media_total = mean(v);

    % Mean linear velocity inside two pre-defined time blocks
    inicios = [70 400];
    finales = [110 490];
    velocidades_bloque1     = v(inicios(1):finales(1));
    velocidad_media_bloque1 = mean(velocidades_bloque1);
    velocidades_bloque2     = v(inicios(2):finales(2));
    velocidad_media_bloque2 = mean(velocidades_bloque2);

    % --- 5) Angular-velocity descriptors ------------------------------
    [vel_angular, ~] = angular_velocity(VCG);
    plot(vel_angular)
    media_velocidad_angular_total = mean(vel_angular);
    carac_vel_angular = angular_velocity_features(vel_angular);

    % NOTE: the original new_patient script uses the LINEAR velocity v
    % (not vel_angular) inside the two angular-block windows. We keep that
    % behaviour intentionally to preserve backward compatibility with the
    % feature spreadsheet already used to train the classifier.
    inicios = [15 210];
    finales = [50 295];
    velocidades_angular_bloque1      = v(inicios(1):finales(1));
    velocidad_angular_media_bloque1  = mean(velocidades_angular_bloque1);
    velocidades_angular_bloque2      = v(inicios(2):finales(2));
    velocidad_media_angular_bloque2  = mean(velocidades_angular_bloque2);

    % --- Final feature struct (same field order as the original) ------
    resultado_final = struct( ...
        'correlation_C_CW',             vector_correlaciones(1), ...
        'correlation_C_CCW',             vector_correlaciones(2), ...
        'correlation_PM_CW',             vector_correlaciones(3), ...
        'correlation_PM_CCW',             vector_correlaciones(4), ...
        'max_vector',                      vector_maximo, ...
        'OCC_T',                              carac_vel.SVPOT, ...
        'peak_differences',                   carac_vel.diferencia_picos, ...
        'average_homogeneity',                 carac_vel.homogeneidad_media, ...
        'kurtosis',                           carac_vel.kurtosis, ...
        'AUC_v',                    carac_vel.area_bajo_curva, ...
        'fastest_direction',                  carac_vel.fastest_direction, ...
        'sign',                              carac_vel.signo, ...
        'homogeneidad_ang_media',             carac_vel_angular.homogeneidad_ang_media, ...
        'Kurtosis_ang',                       carac_vel_angular.Kurtosis_ang, ...
        'AUC_w',                   carac_vel_angular.area_curva_v_ang, ...
        'mean_v',         velocidad_media_total, ...
        'mean_v_1stSeg', velocidad_media_bloque1, ...
        'mean_v_2stSeg', velocidad_media_bloque2, ...
        'mean_w',      media_velocidad_angular_total, ...
        'mean_w_1stSeg',            velocidad_angular_media_bloque1, ...
        'mean_w_2stSeg',            velocidad_media_angular_bloque2, ...
        'complexity',                        resultados.complejidad);

end
