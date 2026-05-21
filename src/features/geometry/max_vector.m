function vector_maximo = max_vector(VCG)
% MAX_VECTOR  Maximum Euclidean norm reached by a (centred) VCG loop.
%
%   vector_maximo = MAX_VECTOR(VCG) returns the maximum 3-D norm of the
%   VCG loop after the per-lead mean has been subtracted (zero_mean).
%   This is the maximum-vector amplitude descriptor used in the feature
%   table.
%
%   Inputs:
%     VCG  --  3 x L matrix with the VCG loop.
%
%   Output:
%     vector_maximo  --  Scalar, max(||VCG(:,t)||_2) over t.
%
% Original author: David Hernandez (UPV).

    VCG_centered = zero_mean(VCG);
    norm_VCG     = vecnorm(VCG_centered);
    vector_maximo = max(norm_VCG);

end
