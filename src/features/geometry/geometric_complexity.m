function [resultado, a, b, x0, y0, phi, complejidad] = geometric_complexity(x, y)
% GEOMETRIC_COMPLEXITY  Geometric-complexity metrics of a 2-D VCG loop.
%
%   [resultado, a, b, x0, y0, phi, complejidad] = GEOMETRIC_COMPLEXITY(x, y)
%   characterises a 2-D projection of the VCG loop (typically the XY
%   plane) by fitting an ellipse to it and comparing the real loop
%   perimeter with the perimeter of the fitted ellipse.
%
%   The function returns:
%     a, b          --  Semi-major and semi-minor axes of the fitted
%                        ellipse.
%     x0, y0        --  Centre of the ellipse.
%     phi           --  Rotation angle of the major axis (degrees, in
%                        [0, 180)).
%     perimetro_vcg --  Real perimeter of the loop (sum of segment
%                        lengths).
%     perimetro_ellipse --  Perimeter of the fitted ellipse, estimated
%                        with Ramanujan's first approximation.
%     complejidad   --  Ratio perimetro_vcg / perimetro_ellipse. Values
%                        close to 1 mean the loop is well approximated by
%                        an ellipse; values >> 1 indicate a complex /
%                        crinkled loop.
%     cilindricidad --  Ratio b / a (closer to 1 -> more circular).
%
%   Inputs:
%     x, y      --  Row vectors with the X and Y coordinates of the loop.
%
%   Outputs:
%     resultado     --  Struct with all the metrics above as fields.
%     a, b, x0, y0, phi, complejidad  --  Also returned individually for
%                                          backward compatibility with the
%                                          original API.
%
% Original author: David Hernandez (UPV).

    % Fit the ellipse using PCA
    [a, b, x0, y0, phi, phi_deg] = ellipse_fit(x, y);

    % Real loop perimeter
    dx = diff(x);
    dy = diff(y);
    perimetro_vcg = sum(hypot(dx, dy));

    % Ellipse perimeter -- Ramanujan's first approximation
    h = (a - b)^2 / (a + b)^2;
    perimetro_elipse = pi * (a + b) * (1 + (3*h) / (10 + sqrt(4 - 3*h)));

    % Complexity / cylindricity metrics
    complejidad = perimetro_vcg / perimetro_elipse;
    cilindricidad = b / a;

    % Pack everything into a struct
    resultado = struct( ...
        'a', a, ...
        'b', b, ...
        'x0', x0, ...
        'y0', y0, ...
        'phi', phi_deg, ...
        'perimetro_vcg', perimetro_vcg, ...
        'perimetro_ellipse', perimetro_elipse, ...
        'complejidad', complejidad, ...
        'cilindricidad', cilindricidad ...
    );
end
