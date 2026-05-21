% =========================================================================
%  cerrar_bucle.m  --  Third-party code
%
%  Source: Internal utility of the EP Analytics Lab / ITACA / UPV group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function VCG = cerrar_bucle(VCG);
[Nleads,Nsamp]= size(VCG); % Nleads = number of rows, Nsamp = number of columns

for i = 1:Nleads
correccion(i,:) = linspace(0,VCG(i,end)-VCG(i,1),length(VCG)); % linspace(start, end, n_points)
% For each row, take the difference between the first and the last column
% and generate an equispaced vector between them
end

VCG = VCG - correccion; % subtract the offset between the first and last column to remove the discontinuity

VCG(:,end) = []; % drop the last column

% VCG = [VCG VCG VCG];
%
% VCG = resample(VCG',1500,length(VCG));
%
% VCG = VCG';
%
% VCG = VCG(:,501:1000);
%
% VCG(1,:) = VCG(1,:) - mean(VCG(1,:));
% VCG(2,:) = VCG(2,:) - mean(VCG(2,:));
% VCG(3,:) = VCG(3,:) - mean(VCG(3,:));
