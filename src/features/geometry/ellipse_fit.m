function [semimajor_axis, semiminor_axis, x0, y0, phi, phi_deg] = ellipse_fit(x, y)
% ELLIPSE_FIT  Fit an ellipse to a 2-D point cloud using PCA.
%
%   [a, b, x0, y0, phi, phi_deg] = ELLIPSE_FIT(x, y) returns the semi-major
%   axis a, semi-minor axis b, centre (x0, y0), rotation angle phi (in
%   radians) and the same angle in degrees (folded to the [0, 180) range)
%   of an ellipse fitted to the 2-D point cloud (x, y).
%
%   The procedure is:
%     1. Centre the data on its mean to compute the PCA of the covariance
%        matrix. The eigenvector with the largest eigenvalue gives the
%        direction of the ellipse's major axis.
%     2. Rotate the ORIGINAL (uncentred) data by -phi to align the major
%        axis with the X axis.
%     3. The semi-axes are estimated as twice the standard deviation of
%        the rotated coordinates (capturing roughly 95% of the dispersion
%        for a Gaussian-like distribution).
%
%   Note: the centre returned (x0, y0) is the empirical mean of the
%   original data.
%
%   Inputs:
%     x, y          --  Row vectors with the X and Y coordinates of the
%                        loop.
%
%   Outputs:
%     semimajor_axis, semiminor_axis  --  Lengths of the ellipse semi-axes.
%     x0, y0                          --  Coordinates of the ellipse centre.
%     phi                             --  Rotation angle of the major axis
%                                          [rad].
%     phi_deg                         --  Same angle wrapped into [0, 180).
%
% Original author: David Hernandez (UPV).

    phi = [];   %#ok<NASGU>  preserved from original

    % 1. Centre
    x0 = mean(x);
    y0 = mean(y);

    % 2. Major-axis direction via PCA on the centred data
    x_centered_for_pca = x - x0;
    y_centered_for_pca = y - y0;
    cov_matrix = cov(x_centered_for_pca, y_centered_for_pca);
    [eigenvectors, eigenvalues] = eig(cov_matrix);

    [~, max_idx] = max(diag(eigenvalues));
    major_dir = eigenvectors(:, max_idx);
    phi = atan2(major_dir(2), major_dir(1));

    % 3. Rotate the ORIGINAL (uncentred) points
    rotation_matrix = [cos(phi) sin(phi); -sin(phi) cos(phi)];
    rotated_points = rotation_matrix * [x; y];

    % 4. Semi-axes from the dispersion of the rotated coordinates
    semimajor_axis = std(rotated_points(1,:)) * 2;
    semiminor_axis = std(rotated_points(2,:)) * 2;

    % The centre stays at (x0, y0); the ellipse will be centred there.

    % Convert phi to degrees, wrapped into [0, 180)
    phi_deg = mod(rad2deg(phi), 180);

end
