function assign_group(VCG, target, correlacion_arquetipos)
% ASSIGN_GROUP  Assign a VCG to the subtype of maximum archetype correlation.
%
%   ASSIGN_GROUP(VCG, target, correlacion_arquetipos) inspects the four
%   correlation values stored in correlacion_arquetipos (one per
%   archetype, in the canonical order C_CW, C_CCW, PM_CW, PM_CCW), and
%   assigns the VCG to the subtype that yielded the maximum correlation.
%
%   If the assigned subtype differs from the ground-truth target, a 2-D
%   plot of the VCG is shown with a title reporting the assignment and
%   the value of the maximum correlation. This is intended as a quick
%   visual aid to identify misclassifications.
%
%   Inputs:
%     VCG                       --  3 x L VCG loop being assigned.
%     target                    --  Ground-truth subtype tag (string),
%                                    e.g. '_C_CW', used only to decide
%                                    whether to plot.
%     correlacion_arquetipos    --  1 x 4 vector of correlations, in the
%                                    order [C_CW, C_CCW, PM_CW, PM_CCW].
%
% Original author: David Hernandez (UPV).

    correlacion_maxima = max(correlacion_arquetipos);

    if max(correlacion_arquetipos) == correlacion_arquetipos(1)
        grupo_asignado = '_C_CW';
    elseif max(correlacion_arquetipos) == correlacion_arquetipos(2)
        grupo_asignado = '_C_CCW';
    elseif max(correlacion_arquetipos) == correlacion_arquetipos(3)
        grupo_asignado = '_PM_CW';
    elseif max(correlacion_arquetipos) == correlacion_arquetipos(4)
        grupo_asignado = '_PM_CCW';
    end

    if ~strcmpi(grupo_asignado, target)
        figure;
        dibuja_VCG(VCG, '2d', 'puntos'),
        title(sprintf('assigned group %s with correlation %d', ...
                      grupo_asignado, correlacion_maxima))
    end

    correlacion_arquetipos = [];   %#ok<NASGU>  preserved from original

end
