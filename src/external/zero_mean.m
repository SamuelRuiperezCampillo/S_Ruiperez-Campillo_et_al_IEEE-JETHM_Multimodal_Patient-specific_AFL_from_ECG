% =========================================================================
%  zero_mean.m  --  Third-party code
%
%  Original author: Vicente Zarzoso Gascon-Pelegri (1999).
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md for
%  full attribution and licensing notes. Do NOT modify.
% =========================================================================

function X = zero_mean(X);

%Removes mean value from input signals.
%
%SYNTAX: Y = zero_mean(X);
%        Y : zero-mean output(s)
%        X : input(s), one signal per row.
%
%(c) 1999 Vicente Zarzoso Gascon-Pelegri.

[m, n] = size(X);
X = X - mean(X')'*ones(1, n) ;
