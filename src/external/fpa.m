% =========================================================================
%  fpa.m  --  Third-party code
%
%  Source: EP Analytics Lab / ITACA / UPV signal-processing group (relies on
%  zero_mean by V. Zarzoso).
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function y = fpa(senyal,fc,fs);
[B1,A1] = butter(3,fc/(fs/2),'high');
%figure;freqz(B1,A1,700,fs);
%figure;zplane(B1,A1);
%return
senyal=zero_mean(senyal);
[nf,nc]=size(senyal);
y=zeros(nf,nc); % output vector allocation
w = waitbar(0,'Filtering...');
for n=1:nf,
	y(n,:)=filtfilt(B1,A1,senyal(n,:));
   waitbar(n/nf);
end;
close(w);
y=zero_mean(y); % remove mean again just in case

%y = filtfilt(B1,A1,senyal);
%freqz(B1,A1,[0:0.1:70],fs)
