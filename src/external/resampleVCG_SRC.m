% =========================================================================
%  resampleVCG_SRC.m  --  Third-party code
%
%  Source: Internal utility of the EP Analytics Lab / ITACA / UPV group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function VCG_out = resampleVCG_SRC(VCG,Npoints)

L1 = length(VCG);
VCG = repmat(VCG,1,1000);

for i = 1:3
    VCG_aux(i,:) = resample(VCG(i,:),Npoints,L1);
end

VCG_out = VCG_aux(:,501:500+Npoints);
