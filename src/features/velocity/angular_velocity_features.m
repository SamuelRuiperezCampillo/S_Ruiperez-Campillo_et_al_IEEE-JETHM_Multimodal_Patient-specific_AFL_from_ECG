function carac_velocidad_angular = angular_velocity_features(v_ang)
% ANGULAR_VELOCITY_FEATURES  Descriptors of the VCG's angular velocity.
%
%   carac_velocidad_angular = ANGULAR_VELOCITY_FEATURES(v_ang) computes a
%   parallel battery of descriptors of the angular velocity, mirroring
%   the ones returned by velocity_features for the linear velocity:
%
%     diferencia_ang           --  max(v_ang) - min(v_ang).
%     diferencia_relativa_ang  --  (max - min) / min.
%     homogeneidad_ang_media   --  (max - min) / mean.
%     homogeneidad_mediana_ang --  (max - min) / median.
%     Kurtosis_ang             --  kurtosis(v_ang).
%     asimetria_ang            --  Fraction of samples above the mean.
%     area_curva_v_ang         --  trapz(v_ang).
%
%   Inputs:
%     v_ang  --  1 x N angular velocity vector (e.g. output of
%                 angular_velocity).
%
%   Output:
%     carac_velocidad_angular  --  Struct with the descriptors above.
%
% Original author: David Hernandez (UPV).

    % 1) Range
    V_ang_max = max(v_ang);
    V_ang_min = min(v_ang);
    diferencia_picos_ang = V_ang_max - V_ang_min;
    diferencia_relativa_ang = (V_ang_max - V_ang_min) / V_ang_min;

    % 2) Homogeneity (relative to mean and median)
    homogeneidad_media_ang   = (V_ang_max - V_ang_min) / mean(v_ang);
    homogeneidad_mediana_ang = (V_ang_max - V_ang_min) / median(v_ang);   % more outlier-sensitive

    % 3) Kurtosis
    kurtosis_ang = kurtosis(v_ang);

    % 4) Asymmetry: fraction of samples above the mean
    asimetria_media = sum(v_ang > mean(v_ang)) / length(v_ang);

    % 5) Area under the angular-velocity curve
    area_v_ang = trapz(v_ang);

    % Pack everything into a struct
    carac_velocidad_angular = struct( ...
        'diferencia_ang', diferencia_picos_ang, ...
        'diferencia_relativa_ang', diferencia_relativa_ang, ...
        'homogeneidad_ang_media', homogeneidad_media_ang, ...
        'homogeneidad_mediana_ang', homogeneidad_mediana_ang, ...
        'Kurtosis_ang', kurtosis_ang, ...
        'asimetria_ang', asimetria_media, ...
        'area_curva_v_ang', area_v_ang);

end
