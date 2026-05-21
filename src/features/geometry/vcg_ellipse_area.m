function [area_VCG, area_elipse, diferencia] = vcg_ellipse_area(VCG)
% VCG_ELLIPSE_AREA  Compare the area enclosed by the VCG loop in the XZ
%                   plane with the area of the ellipse fitted to it.
%
%   [area_VCG, area_elipse, diferencia] = VCG_ELLIPSE_AREA(VCG) takes a
%   3-D VCG tensor (or a single loop) and, for each loop, returns:
%     - The real area enclosed by the loop in the XZ plane, computed via
%       trapezoidal integration per quadrant (compute_area_loop).
%     - The area of the ellipse fitted to the XZ projection of the loop
%       (pi * a * b).
%     - Their difference (area_elipse - area_VCG).
%
%   Before the area calculation each loop is centred (zero_mean) and
%   amplitude-normalised (normalizeVCG_Amplitude).
%
%   Inputs:
%     VCG  --  3 x L x N tensor (or 3 x L matrix) with the VCG loop(s).
%
%   Outputs (when VCG contains a single loop):
%     area_VCG     --  Area of the loop in the XZ plane.
%     area_elipse  --  Area of the fitted ellipse.
%     diferencia   --  area_elipse - area_VCG.
%
%   NOTE: when VCG has more than one loop along the 3rd dimension, the
%   outputs hold the values of the LAST loop (this matches the original
%   behaviour and is preserved intentionally).
%
% Original author: David Hernandez (UPV).

    VCG_centered = [];
    for i = 1:size(VCG, 3)
        % Centre the loop at (0,0)
        VCG_centered(:,:,i) = normalizeVCG_Amplitude(zero_mean(VCG(:,:,i)));
    end

    for i = 1:size(VCG_centered, 3)
        % Keep X and Z components (XZ plane)
        VCG = VCG_centered(:,:,i);
        VCG_xz = VCG([1, 3], :);

        % Real loop area (XZ plane)
        area_VCG = compute_area_loop(VCG_xz);

        % Ellipse area fitted in the XZ plane
        [semieje_mayor, semieje_menor] = ellipse_fit(VCG(1,:), VCG(3,:));
        area_elipse = pi * semieje_mayor * semieje_menor;

        % Difference
        diferencia = area_elipse - area_VCG;
    end

end
