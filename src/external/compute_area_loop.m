% =========================================================================
%  compute_area_loop.m  --  Third-party code
%
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify. The original header (with mandatory citation) is preserved
%  below.
% =========================================================================

% *************************************************************************
% QCEP ITACA UPV
% Omnipolar Evaluation and Assessment
%
% Authors: Marina Crespo, Izan Segarra, Samuel Ruiperez-Campillo, Francisco
% Castells.
% Date: 10/08/2022
%
% Any individual benefiting from any of this code must cite the work as:
% S. Ruiperez-Campillo, M. Crespo, F. Castells, A. Tormos, A. Guill,
% A. Alberola R. Cervigon, J. Heimer, F. J Chorro, J. Millet, F.
% Castells.
% Evaluation and Assessment of Clique Arrangements for the Estimation of
% Omnipolar Electrograms in High Density Electrode Arrays:
% An Experimental Animal Model Study,
% Physical and Engineering Sciences in Medicine (2023).
%
% Description: Function that estimates the area contained within the
% bipolar loop by means of a trapezoidal numerical integration
% *************************************************************************
% COMPUTE_AREA_LOOP Estimates the area contained within the bipole
%
% [area_total] = COMPUTE_AREA_LOOP (b_egm)
%
%     Parameters
%         b_egm (Double): Matrix (2 x ...) with the horizontal and vertical
%         components of the bipole
%
%     Returns
%         area_total (Double): Value of the area contained within the
%             bipolar loop

function [area_total] = compute_area_loop(bipole)
%     bipole = close_bipole(bipole);
    quad_1 = [];
    quad_2 = [];
    quad_3 = [];
    quad_4 = [];

    area_total = 0;

    for i = 1:size(bipole,2)
        if bipole(1,i) > 0 && bipole(2,i) > 0
            quad_1 = [quad_1 i];
        elseif bipole(1,i) < 0 && bipole(2,i) > 0
            quad_2 = [quad_2 i];
        elseif bipole(1,i) < 0 && bipole(2,i) < 0
            quad_3 = [quad_3 i];
        elseif bipole(1,i) > 0 && bipole(2,i) < 0
            quad_4 = [quad_4 i];
        end
    end

    b_egm_quad_1 = bipole(:,quad_1);
    b_egm_quad_2 = bipole(:,quad_2);
    b_egm_quad_3 = bipole(:,quad_3);
    b_egm_quad_4 = bipole(:,quad_4);

    for i = 1:4
        switch i
            case 1
                bipole_quadrant = b_egm_quad_1;
            case 2
                bipole_quadrant = b_egm_quad_2;
            case 3
                bipole_quadrant = b_egm_quad_3;
            case 4
                bipole_quadrant = b_egm_quad_4;
        end

        if isempty(bipole_quadrant) == 0 && size(bipole_quadrant,2) > 2
            area = abs(trapz(bipole_quadrant(1,:), bipole_quadrant(2,:)));
        else
            area = 0;
        end

        area_total = area_total + area;
    end
end
