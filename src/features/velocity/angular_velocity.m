function [theta, t] = angular_velocity(VCG)
% ANGULAR_VELOCITY  Sample-to-sample angular velocity of a 3-D VCG loop.
%
%   [theta, t] = ANGULAR_VELOCITY(VCG) returns the angle (in radians)
%   between every pair of consecutive 3-D vectors VCG(:,i) and VCG(:,i+1)
%   along the loop. The angle is computed from the dot product of the
%   normalised vectors (cosine-based formulation, clamped to [-1, 1] to
%   avoid acos domain errors). To produce an output of the same length
%   as the input, the value at index 1 is appended at the end.
%
%   The function does NOT require knowing the cycle duration.
%
%   Inputs:
%     VCG  --  3 x L VCG loop.
%
%   Outputs:
%     theta  --  1 x L vector of inter-sample angles (radians).
%     t      --  1 x L time index vector (1..L).
%
% Original author: David Hernandez (UPV).

    L = size(VCG, 2);
    theta = zeros(1, L-1);
    for i = 1:(L-1)
        v1 = VCG(:, i);
        v2 = VCG(:, i+1);
        normV1 = norm(v1);
        normV2 = norm(v2);
        cos_val = (v1' * v2) / (normV1 .* normV2);
        cos_val = max(min(cos_val, 1), -1);   % clamp to valid acos domain
        theta(i) = acos(cos_val);
    end
    theta = [theta theta(1)];   % pad to the same length as the input
    t = 1:L;                    % time index

end
