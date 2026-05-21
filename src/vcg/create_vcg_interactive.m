function VCGMatrix = create_vcg_interactive(ECG, fs)
% CREATE_VCG_INTERACTIVE  Build the averaged VCG loop from a raw 12-lead ECG.
%
%   VCGMatrix = CREATE_VCG_INTERACTIVE(ECG, fs) performs the full
%   preprocessing pipeline to obtain an averaged Vectorcardiogram (VCG)
%   loop from a raw 12-lead ECG signal:
%
%     1. High-pass (fpa) and low-pass (lpf_ecg) filtering.
%     2. Automatic F-wave segment selection (select_f_waves), used only as
%        a visual aid to guide the manual selection step below.
%     3. Interactive selection (ginput) of the clean atrial segment by the
%        user on the filtered ECG plot.
%     4. Inverse Dower transform (calcula_y_dibuja_VCG -> idowerT) to map
%        the 12-lead ECG into a 3-lead VCG.
%     5. Automatic detection of the cycle length and number of cycles via
%        autocorrelation, with two safeguards against spurious early peaks.
%     6. Per-cycle averaging of the VCG loop, loop closure (cerrar_bucle)
%        and zero-mean alignment to the Cartesian axes.
%
%   The function generates diagnostic figures along the way (filtered ECG,
%   autocorrelation, cycle markers, VCG in 2D / 3D).
%
%   Input:
%     ECG  --  12 x N raw ECG matrix.
%     fs   --  Sampling frequency in Hz (typically 1000).
%
%   Output:
%     VCGMatrix  --  3 x M averaged VCG loop, closed and centred.
%
% Original author: David Hernandez (UPV).

    % --- 1. Filtering -----------------------------------------------------
    ECG = fpa(ECG, 1.5, fs);          % high-pass (baseline wander)
    ECG = lpf_ecg(ECG, fs, 30);       % low-pass (HF noise)

    % --- 2. Visual F-wave selection helper --------------------------------
    matriz_F = select_f_waves(ECG);   %#ok<NASGU>  shown only as overlay

    % --- 3. Manual segment selection via ginput ---------------------------
    [x, y] = ginput(2);
    initial = x(1);
    final   = x(2);

    % Keep only the user-selected segment of the (already filtered) ECG
    ECGatrium = ECG(:, initial:final);
    plot(ECGatrium(2,:))

    derivacionII = ECGatrium(2,:);

    % --- 4. ECG -> VCG (inverse Dower transform + loop closure) -----------
    VCG = calcula_y_dibuja_VCG(ECGatrium, 'linea');

    % --- 5. Cycle length and cycle count via autocorrelation --------------
    R = xcorr(VCG(1,:), VCG(1,:), 'coef');   % normalised autocorrelation (-1..1) of lead X
    L = length(R);
    R = R(ceil(L/2):end);                    % keep the positive-lag side
    figure; plot(R), hold on
    [peak, position] = findpeaks(R);
    plot(position, peak, 'o'), hold off

    cyclelength = position(1) - 1;                     % length of the first cycle
    ncycles     = floor(length(VCG) / cyclelength);    % number of complete cycles

    % Safeguard against spurious low first peaks (1 false small peak)
    if peak(1) < 0 | peak(1) < (peak(2)/2)
        cyclelength = position(2) - 1;
        ncycles     = floor(length(VCG) / cyclelength);
    end
    % Safeguard against two spurious small peaks at the start
    if (peak(1) < 0 | peak(1) < peak(3)/2) && (peak(2) < 0 | peak(2) < peak(3)/2)
        cyclelength = position(3) - 1;
        ncycles     = floor(length(VCG) / cyclelength);
    end

    fprintf('\n%d cycles are represented of length in time = %d \n \n', ncycles, cyclelength)

    % --- 5b. Plot detected cycle boundaries on lead II for verification ----
    puntos = zeros(size(ncycles));
    n = 1;
    for i = 1:ncycles
        punto = n * cyclelength + 1;
        puntos(i) = punto;
        n = n + 1;
    end

    figure; plot(derivacionII); hold on
    plot(puntos, derivacionII(puntos), 'o'), title('Detected cycles'), hold off

    % --- 6. Per-cycle averaging of the VCG --------------------------------
    for i = 1:ncycles
        VCGMatrix(:,:,i) = VCG(:, (i-1)*cyclelength + 1 : i*cyclelength);
    end
    size(VCGMatrix)
    VCGMatrix = mean(VCGMatrix, 3);          % average across cycles (3rd dim)

    % Close the VCG loop (removes discontinuity between first and last sample)
    VCG_2 = cerrar_bucle(VCGMatrix);
    VCGMatrix = [VCG_2 VCG_2(:,1)];           % append first sample so the loop starts and ends equally

    % Align the VCG to the Cartesian axes
    VCGMatrix = zero_mean(VCGMatrix);

    % --- 7. Diagnostic plots of the final averaged VCG --------------------
    figure; dibuja_VCG(VCGMatrix, '2d', 'puntos')
    figure; dibuja_VCG(VCGMatrix, '2d', 'linea')

    figure; tiledlayout(3,1);
    nexttile; plot(VCGMatrix(1,:)), title('X axis')
    nexttile; plot(VCGMatrix(2,:)), title('Y axis')
    nexttile; plot(VCGMatrix(3,:)), title('Z axis')

    figure; dibuja_VCG(VCGMatrix, '3d', 'puntos')
    figure; dibuja_VCG(VCGMatrix, '3d', 'linea')

end
