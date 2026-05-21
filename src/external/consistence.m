% =========================================================================
%  consistence.m  --  Third-party code
%
%  Source: Internal utility of the EP Analytics Lab / ITACA / UPV group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function [C1,C2,C3] = consistence(VCG_tensor)
% [C1,C2] = consistence(VCG_tensor)
%
% C1: variance percentage of the first component
% C2: singular value percentage of the first component
%
% VCG_tensor
%     files: XYZ components
%     columns: number of samples
%     3rd dimension: n-th VCG loop

[~,~,n_VCGs] = size(VCG_tensor);

for i = 1:n_VCGs
    VCG_aux = VCG_tensor(:,:,i);
    VCG(:,i) = VCG_aux(:);
end

[coeff,score,latent,tsquared,explained,mu] = pca(VCG, 'Centered', true,  'Algorithm','eig','Rows','complete','Economy',false, 'VariableWeights', 'variance');


% Explained variance (per unit)
explained_all = explained / sum(explained) * 100;
C1 = explained_all(1);
C2 = explained_all(2);
C3 = explained_all(3);
