% =========================================================================
%  idowerT.m  --  Third-party code
%
%  Original author: Gari D. Clifford, April 2006.
%  Source: http://alum.mit.edu/www/gari/ecgtools
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify. Original header preserved below.
% =========================================================================

function [vcg,leadvcg] = idowerT(signal);
% Matlab function to apply inverse Dower transformation to construct VCG.
%
%[vcg,leadvcg] = idowerT(signal);
%
% Gari D. Clifford April 2006  http://alum.mit.edu/www/gari/ecgtools

% Although several methods have been proposed for synthesizing the VCG from the 12-lead ECG,
% the inverse transformation matrix of Dower is the most commonly used [31]. Dower et al. presented
% a method for deriving the 12-lead ECG from Frank lead VCG [44]. Each ECG lead is calculated as
% a weighted sum of the VCG leads X, Y and Z using lead-specic coefcients based on the image
% surface data from the original torso studies by Frank [45]. The transformation operation used to
% derive the eight independent leads (V1-V6, I and II) of the 12-lead ECG from the VCG leads is
% given by, s=Dv, where

D = [
-0.515  0.157   -0.917;
 0.044  0.164   -1.387;
 0.882  0.098   -1.277;
 1.213  0.127   -0.601;
 1.125  0.127   -0.086;
 0.831  0.076    0.230;
 0.632 -0.235    0.059;
 0.235  1.066   -0.132];



% where s(n)=[V1(n) V2(n) V3(n) V4(n) V5(n) V6(n) I(n) II(n)]^T and v(n)=[X(n) Y (n) Z(n)]^T
% contain the voltages of the corresponding leads, n denotes sample index and D is called the Dower
% transformation matrix. From s=Dv, it follows that the VCG leads can be synthesized from the 12-lead
% ECG by  v(n) = Ts(n);  where T=pinv(D'*D)*D' is called the inverse Dower transformation matrix
% and is given by

T = [ -0.172 -0.074  0.122  0.231 0.239 0.194  0.156 -0.010 ;
       0.057 -0.019 -0.106 -0.022 0.041 0.048 -0.227  0.887 ;
      -0.229 -0.310 -0.246 -0.063 0.055 0.108  0.022  0.102 ]; % 3x8 matrix

% check with    TT=pinv(D'*D)*D';

% so the inverse Dower transform is :
signal = signal([7:12 1:2],:); % reorder leads: first V1-V6 (rows 7-12) and then I, II (rows 1-2); rest are linear combinations --> 8xN matrix

vcg = T*signal; % VCG becomes 3xN

leadvcg(1,1)='X';
leadvcg(2,1)='Y';
leadvcg(3,1)='Z';
