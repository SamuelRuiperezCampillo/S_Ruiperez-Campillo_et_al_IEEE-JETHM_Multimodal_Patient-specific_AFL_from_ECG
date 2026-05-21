% =========================================================================
%  normalizeVCG_Amplitude.m  --  Third-party code
%
%  Source: Internal utility of the EP Analytics Lab / ITACA / UPV VCG analysis group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md for
%  full attribution. Do NOT modify.
% =========================================================================

function VCG_n = normalizeVCG_Amplitude(VCG)


[fil,col] = size(VCG);

% Control of VCG orientation (matrix dimensions)
trasponer = 0;
if fil>col
    trasponer = 1;
    VCG = VCG';
end


VCG_n = VCG/mean(sqrt(sum(VCG.^2)));

if trasponer
    VCG_n = VCG_n';
end
