function [Vi, Vf] = detect_slow_zones(velocity, condicion, VCGMatrix)
% DETECT_SLOW_ZONES  Find low-velocity intervals along the VCG loop.
%
%   [Vi, Vf] = DETECT_SLOW_ZONES(velocity, condicion, VCGMatrix) detects
%   the time intervals where the instantaneous velocity is below
%   max(velocity) / condicion. Vi contains the starting samples of each
%   slow interval, Vf the ending samples.
%
%   The function also plots the velocity time series and highlights the
%   detected slow intervals.
%
%   Inputs:
%     velocity   --  1 x N velocity vector (typically the output of
%                     velocidad_VCG).
%     condicion  --  Denominator of the threshold; the slow-velocity
%                     condition is  velocity < max(velocity)/condicion .
%                     Typical value: 4 (i.e. 25% of the maximum velocity).
%     VCGMatrix  --  3 x N VCG loop. Currently unused inside the function
%                     but kept in the signature for backward compatibility
%                     with the original API.
%
%   Outputs:
%     Vi  --  Starting samples of every detected slow interval.
%     Vf  --  Ending samples of every detected slow interval.
%
% Original author: David Hernandez (UPV).

    condition = ((max(velocity)) / condicion);
    fprintf('The condition for low velocity is velocity < %.2f, which is 1/%d of the maximum velocity. \n', ...
            condition, condicion);

    n  = 1;
    m  = 1;
    Vi = zeros;
    Vf = zeros;

    for j = 2:length(velocity)
        % Slow interval that starts at the very beginning of the signal
        if j == 2 && velocity(1) < condition
            Vi(n) = 1;
            n = n + 1;
        end
        % Transition from high to low velocity
        if velocity(j) <= condition && velocity(j-1) > condition
            Vi(n) = j;     % current point is slow, previous was fast
            n = n + 1;
        end
        % Transition from low to high velocity
        if velocity(j) > condition && velocity(j-1) <= condition
            Vf(m) = j;     % current point is fast, previous was slow
            m = m + 1;
        end
    end

    % Slow interval that extends until the end of the signal
    if velocity(length(velocity)) <= condition
        Vf(m) = length(velocity);
    end

    % --- Visualisation --------------------------------------------------
    if Vi ~= 0
        fprintf('Number of slow zones %d:\n', length(Vi))
        figure;
        colores = ['k', 'k', 'k', 'k', 'k'];
        plot(velocity, 'Color', [0.5 0.5 0.5]')
        if length(Vi) == length(Vf)
            for i = 1:length(Vi)
                hold on
                color_idx = mod(i-1, length(colores)) + 1;
                plot(Vi(i):Vf(i), velocity(Vi(i):Vf(i)), colores(color_idx), 'LineWidth', 2)
                hold off
            end
            title(['\fontsize{14} \color[rgb]{0 .5 .5} \fontname{Georgia} Low Velocity Regions vs Time Through the Average VCG Loop']);
            xlabel('\fontsize{12} \fontname{Times New Roman}  \bf Time (ms)');
            ylabel('\fontsize{12} \fontname{Times New Roman}  \bf Velocity');
            set(gca, 'fontname', 'Times New Roman', 'FontSize', 12)
            grid on
            grid minor
            xlim([0 length(velocity)]);
        else
            fprintf('Error with the condition, too many low velocity frames (>7): %d \n', length(Vi));
        end
    else
        disp('Calculation error')
    end

end
