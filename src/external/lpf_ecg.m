% =========================================================================
%  lpf_ecg.m  --  Third-party code
%
%  Original author: J. J. Rieta, Universitat Politecnica de Valencia
%  (July 2000).
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function y=lpf_ecg(ECG,fs,fc,rep)

% Low-pass filtering of an ECG using a Chebyshev order-8 with flat
% pass-band and ripple in the stop band. Bidirectional filtering is used
% to minimise filter transients. Intended to remove high-frequency noise
% from the ECG.
%
% ==========  SYNTAX  =============
% y = lpf_ecg (ECG, fs, fc, rep)
% ==========  INPUT ARGUMENTS  ==========
% ECG: vector or matrix (each lead in one row) of ECG signal
% fs:  sampling frequency [Hz] of the ECG
% fc:  cutoff frequency of the low-pass filter [Hz]
%      Recommended between 75 and 100 Hz
% rep: If 0 or omitted, no plot. Optional parameter.
%      If 1 or greater, plots the filtered ECG corresponding to that row
%      of the input matrix.
% ==========  OUTPUT ARGUMENTS  ==========
% y:   vector or matrix of low-pass-filtered ECG
% ===========================================================
%   _______________________________________________
%  |                                               |
%  |  PROGRAMMED BY J.J. RIETA, July 2000          |
%  |                jjrieta@eln.upv.es             |
%  |_______________________________________________|

ECG=zero_mean(ECG);
[nf,nc]=size(ECG);
y=zeros(nf,nc); % output vector allocation

if nf > nc, % check input format (signals must be on rows)
	disp(' ');
	disp('WARNING: invalid format. Function aborted.');
	disp('Each lead must be on a row!')
	return;
end;
fcn=fc*2/fs; % normalised cutoff frequency
[b,a]=cheby2(8,40,fcn);
%figure;freqz(b,a,700,fs);
%figure;zplane(b,a);
%return
w = waitbar(0,'Filtering...');
for n=1:nf,
   y(n,:)=filtfilt(b,a,ECG(n,:));
   waitbar(n/nf);
end;
close(w);
y=zero_mean(y); % remove mean again just in case

% Plotting
if nargin < 4, rep=0; end;

if (rep > 0) & (rep <= nf)
	plot(y(rep,:));
elseif (rep > 0) & (rep > nf)
	disp(' ');
	disp('WARNING: invalid call. Plot aborted.');
	disp('You can only visualise as many ECGs as there are rows in the input matrix.')
end;
