function [v, velocidad, carac_vel] = velocity_features(VCG)
% VELOCITY_FEATURES  Linear velocity descriptors of the VCG loop.
%
%   [v, velocidad, carac_vel] = VELOCITY_FEATURES(VCG) computes a battery
%   of descriptors of the linear (translation) velocity along the
%   averaged VCG loop:
%
%     SVPOT      --  Slow-Velocity Percentage Of Time:
%                     fraction of the loop spent in slow-conduction zones.
%     SVPOD      --  Slow-Velocity Percentage Of Distance:
%                     fraction of the total loop length covered while in
%                     slow-conduction zones.
%     ratio      --  SVPOT / SVPOD.
%     diferencia_picos     --  max(v) - min(v).
%     diferencia_relativa  --  (max(v) - min(v)) / min(v).
%     homogeneidad_media   --  (max(v) - min(v)) / mean(v).
%     homogeneidad_mediana --  (max(v) - min(v)) / median(v).
%     kurtosis             --  kurtosis(v).
%     asimetria            --  Fraction of samples above the mean velocity.
%     area_bajo_curva      --  trapz(v).
%     direccion            --  Signed dominant axis in the slowest zone
%                               (output of velocidad_VCG).
%     fastest_direction    --  Dominant axis index in the slowest zone.
%     signo                --  Sign of the dominant component.
%
%   The velocity is computed sample-by-sample with velocidad_VCG (fs = 1000)
%   and then smoothed with a Savitzky-Golay filter (order 3, window 11).
%
%   Inputs:
%     VCG  --  3 x L averaged VCG loop.
%
%   Outputs:
%     v          --  1 x (L-1) smoothed velocity vector.
%     velocidad  --  Struct with field 'velocidad' = raw velocity vector
%                     (preserved from the original API).
%     carac_vel  --  Struct with all the descriptors listed above.
%
% Original author: David Hernandez (UPV).

    % 1) Compute the velocity
    [v, ~, direccion, fastest_direction, signo] = velocidad_VCG(VCG, 1000);
    velocidad = struct('velocidad', v);
    v = sgolayfilt(v, 3, 11, [], 2);

    % 2) Detect slow zones
    [Vi, Vf] = detect_slow_zones(v, 4, VCG);

    % 3) SVPOT -- fraction of TIME spent in slow zones
    sumofvelocity = 0;
    for j = 1:length(Vi)
        sumofvelocity = (Vf(j) - Vi(j)) + sumofvelocity;
    end
    SVPOT = sumofvelocity / length(v);

    % 4) SVPOD -- fraction of LOOP LENGTH covered in slow zones
    dist_total = sum(sqrt(sum(diff(VCG, 1, 2).^2, 1)));

    dist_lenta = 0;
    for k = 1:length(Vi)
        segmento = VCG(:, Vi(k):Vf(k));
        d_segmento = sum(sqrt(sum(diff(segmento, 1, 2).^2, 1)));
        dist_lenta = dist_lenta + d_segmento;
    end

    SVPOD = dist_lenta / dist_total;

    % 5) SVPOT / SVPOD ratio (with 0/0 protection)
    ratio = SVPOT / SVPOD;
    if SVPOD == 0 && SVPOT == 0
        ratio = 0;
    end

    % 6) Velocity-range descriptors
    Vmax = max(v);
    Vmin = min(v);
    diferencia          = (Vmax - Vmin);
    diferencia_relativa = (Vmax - Vmin) / Vmin;

    % 7) Profile homogeneity (relative to mean and median)
    homogeneidad_media   = (Vmax - Vmin) / mean(v);
    homogeneidad_mediana = (Vmax - Vmin) / median(v);   % more sensitive to outliers

    % 9) Kurtosis (peakedness around the mean):
    %   > 3 -> leptokurtic (sharper);   < 3 -> platykurtic (flatter)
    kurtosis_v = kurtosis(v);

    % 10) Asymmetry: fraction of samples above the mean
    asimetria_media = sum(v > mean(v)) / length(v);

    % 11) Area under the velocity curve (energy proxy)
    area_vel = trapz(v);

    % Pack everything into a struct
    carac_vel = struct( ...
        'SVPOT', SVPOT, ...
        'SVPOD', SVPOD, ...
        'ratio', ratio, ...
        'diferencia_picos', diferencia, ...
        'diferencia_relativa', diferencia_relativa, ...
        'homogeneidad_media', homogeneidad_media, ...
        'homogeneidad_mediana', homogeneidad_mediana, ...
        'kurtosis', kurtosis_v, ...
        'asimetria', asimetria_media, ...
        'area_bajo_curva', area_vel, ...
        'direccion', direccion, ...
        'fastest_direction', fastest_direction, ...
        'signo', signo);
    % direccion = signo (+/-) * fastest_direction (x, y or z)

end
