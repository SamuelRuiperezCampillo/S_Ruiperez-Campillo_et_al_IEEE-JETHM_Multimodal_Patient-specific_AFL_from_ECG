% =========================================================================
%  corr_VCG_SRC.m  --  Third-party code
%
%  Source: Internal utility of the EP Analytics Lab / ITACA / UPV group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function correlationofVCG = corr_VCG_SRC(VCG1,VCG2)

    [L1] = length(VCG1); % L1 is the number of columns, i.e. the number of points per cycle
%
 % *this loop is repeated for each point of the cycle*
    for k=1:L1
            if k > 1
                VCG3 = [VCG2(:,k:L1) VCG2(:,1:k-1)]; % when k>1, rebuild VCG2 (into VCG3) by placing K:end first, then 1:K-1 (cyclic rotation by k samples)
            else % when k=1 no rotation is applied
                VCG3 = VCG2;
            end
        correlation = zeros(1,L1); % allocate correlation values
        for i = 1:L1
            correlation(i) = VCG1(:,i)'*VCG3(:,i)/sqrt((VCG1(1,i)^2+VCG1(2,i)^2+VCG1(3,i)^2)*(VCG3(1,i)^2+VCG3(2,i)^2+VCG3(3,i)^2)); % cosine of the angle between corresponding points
%                 clf
%                 subplot(1,3,1); plot([0 VCG1(1,i)],[0 -VCG1(2,i)]); hold on; plot([0 VCG2(1,i)],[0 -VCG2(2,i)]); xlim([-400 400]), ylim([-400 400]);
%                 subplot(1,3,2); plot([0 VCG1(1,i)],[0 VCG1(3,i)]); hold on; plot([0 VCG2(1,i)],[0 VCG2(3,i)]); xlim([-400 400]), ylim([-400 400]);
%                 subplot(1,3,3); plot([0 VCG1(3,i)],[0 -VCG1(2,i)]); hold on; plot([0 VCG2(3,i)],[0 -VCG2(2,i)]); xlim([-400 400]), ylim([-400 400]);
%                 pause
        end
        correlationofVCG(k) = mean(correlation); % average over all points for this rotation k
    end
