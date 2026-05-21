% =========================================================================
%  velocidad_VCG.m  --  Third-party code
%
%  Source: Internal utility of the EP Analytics Lab / ITACA / UPV VCG analysis group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function [v, V, direccion, fastest_direction, signo] = velocidad_VCG(VCG,fs)
%[v, V, fastest_direction] = velocidad_VCG(VCG,fs);

% Velocity = S / T. Distance between 2 points:
% D(a,b) = sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
v = sqrt((VCG(1,2:end)-VCG(1,1:end-1)).^2+(VCG(2,2:end)-VCG(2,1:end-1)).^2+(VCG(3,2:end)-VCG(3,1:end-1)).^2)*fs/1000; % row vector with the 3D Euclidean velocity
% fs/1000 converts to velocity in physical units

% Velocity per axis
V(1,:) = (VCG(1,2:end)-VCG(1,1:end-1))*fs/1000;
V(2,:) = (VCG(2,2:end)-VCG(2,1:end-1))*fs/1000;
V(3,:) = (VCG(3,2:end)-VCG(3,1:end-1))*fs/1000;

[minim,pos] = min(v); % index of the minimum velocity value
[maxim,fastest_direction] = max(abs(V(:,pos))); % dominant axis of travel at the slowest point
% returns a column index
signo = sign(V(fastest_direction,pos)); % sign of the dominant axis at the slow point
direccion= fastest_direction*signo % signed direction (added by DH for direction-of-travel readout)
switch fastest_direction*signo
    case 1
        disp('It travels on the X direction in the slowest region.');
    case -1
        disp('It travels on the -X direction in the slowest region.');
    case 2
        disp('It travels on the -Y direction in the slowest region.');
    case -2
        disp('It travels on the Y direction in the slowest region.');
    case 3
        disp('It travels on the Z direction in the slowest region.');
    case -3
        disp('It travels on the -Z direction in the slowest region.');
end
