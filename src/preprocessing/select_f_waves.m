function matriz_F = select_f_waves(ECG)
% SELECT_F_WAVES  Extract the atrial (F-wave) segment from a 12-lead ECG.
%
%   matriz_F = SELECT_F_WAVES(ECG) takes a 12 x N raw ECG matrix sampled at
%   1000 Hz and returns a 12 x M matrix containing the atrial (F-wave)
%   segment, with the QRS peaks removed.
%
%   The algorithm:
%     1. Removes baseline wander per lead using a 400-sample median filter.
%     2. Detects R-peak locations in each lead (dynamic threshold at 30%
%        of the max absolute amplitude, minimum 600 ms between peaks).
%     3. Picks, per lead, the longest inter-peak interval (which is most
%        likely an atrial segment uncontaminated by ventricular activity).
%     4. Trims the inter-peak interval to its central 15%-75% to remove
%        residual P/T-wave deflections.
%     5. Uses the start of the trimmed F-wave segment of lead II as the
%        anchor point, and extracts the same window in all 12 leads.
%
%   The window length is the minimum of (shortest per-lead F-wave length)
%   and 1000 samples, guaranteeing at least one full atrial cycle.
%
%   Two figures are generated:
%     - Lead II raw signal vs estimated baseline.
%     - Lead II filtered signal with the selected F-wave region highlighted.
%
%   Input:
%     ECG  --  12 x N matrix, raw ECG signal at fs = 1000 Hz.
%
%   Output:
%     matriz_F  --  12 x M matrix with the selected F-wave segment.
%
% Original author: David Hernandez (UPV).

fs = 1000;                       % sampling frequency in Hz
t  = (0:length(ECG)-1) / fs;     % time vector

% Storage for filtered leads and per-lead F-wave lengths
matriz_ECG_filtrada = [];
s = zeros(1,12);                 % length of the trimmed F-wave segment per lead

% --- 1. Baseline-wander removal (per lead) ---------------------------------
for i = 1:12
    baseline = medfilt1(ECG(i,:), 400);
    ECG_filtrada = ECG(i,:) - baseline;
    matriz_ECG_filtrada(i,:) = ECG_filtrada;
end

% Diagnostic figures on lead II (last iteration values of "baseline" and
% "ECG_filtrada" refer to lead 12; here we show lead II explicitly for
% clarity).
figure;
plot(t, ECG(end,:)), title('Lead II (unfiltered)')
hold on, plot(t, baseline), hold off
legend('Original lead', 'Baseline')
figure;
plot(t, ECG_filtrada), title('Lead II (filtered)')

% --- 2. R-peak detection and F-wave selection (per lead) -------------------
for i = 1:12
    senyal_filtrada = matriz_ECG_filtrada(i,:);

    % Dynamic threshold: 30% of the max absolute amplitude
    umbral = 0.3 * max(abs(senyal_filtrada));

    % Take absolute value to capture negative peaks too
    [peaks, locs] = findpeaks(abs(senyal_filtrada), ...
        'MinPeakHeight', umbral, ...
        'MinPeakDistance', fs * 0.6);
    N = length(locs);

    % --- 3. Partition the signal between peaks and keep the longest piece
    long = zeros(size(N-1));

    for j = 1:N-1
        ondasF = senyal_filtrada(locs(j):locs(j+1));
        long(j) = length(ondasF);
    end

    % --- 4. Pick the longest inter-peak interval
    [value, idx] = max(long);
    if N == 1
        ondaFtotal = senyal_filtrada(1:locs(idx));
    else
        ondaFtotal = senyal_filtrada(locs(idx):locs(idx+1));
    end

    length(ondaFtotal);
    if N == 1
        ejeX_ondaF_total = (1:length(ondaFtotal));
    else
        ejeX_ondaF_total = (locs(idx):locs(idx) + length(ondaFtotal) - 1);
    end

    % --- 5. Trim the segment to its central 15%-75% to avoid residual peaks
    n = length(ondaFtotal);
    limite_down = round(0.15 * n);
    limite_up   = round(0.75 * n);
    ejeX_ondaF  = ejeX_ondaF_total(limite_down:limite_up);
    ondaF       = ondaFtotal(limite_down:limite_up);

    % Diagnostic figure: lead II only
    if i == 2
        figure;
        plot(senyal_filtrada);
        title(sprintf('findpeaks filtered signal %d', i))
        hold on
        plot(ejeX_ondaF_total, ondaFtotal), title(sprintf('F-wave segment, lead %d', i))
        plot(ejeX_ondaF, ondaF), title(sprintf('selected F-waves, lead %d', i))
        legend('Full signal', 'F-waves (selected)', 'F-waves (trimmed)')
        hold off
    end

    s(i) = length(ondaF);

    % Anchor the extraction window to the start of the F-wave segment of
    % lead II. NOTE: the inner "for i=2" overwrites the loop counter but
    % is kept intentionally (and matches the original behaviour): the
    % anchor is updated only when the outer iteration reaches lead II,
    % and MATLAB resumes the outer loop from i=3 afterwards.
    for i = 2
        punto_inicio = ejeX_ondaF(1);
    end
end

% --- 6. Build the final F-wave window across all 12 leads ------------------
% Guarantee at least one full atrial cycle: cap the window at 1000 samples.
longitud_deseada = min(min(s), 1000);

window = punto_inicio : punto_inicio + longitud_deseada - 1;

matriz_F = [];
for x = 1:12
    senyal_filtrada = matriz_ECG_filtrada(x,:);
    matriz_F(x,:) = senyal_filtrada(window);
end

end
