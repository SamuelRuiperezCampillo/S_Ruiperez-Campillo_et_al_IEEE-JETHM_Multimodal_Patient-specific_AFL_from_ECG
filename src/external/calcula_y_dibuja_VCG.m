% =========================================================================
%  calcula_y_dibuja_VCG.m  --  Third-party code
%
%  Source: Internal wrapper of the EP Analytics Lab / ITACA / UPV group. Combines
%  idowerT (12-lead -> VCG) with cerrar_bucle and plotting via dibuja_VCG.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
%
%  Note: the branch handling 67-row inputs relies on an external
%  ders_estandar function that is not bundled in this repository, since the
%  pipeline only uses 12-lead ECG inputs. Calling the function with a 67-row
%  input would therefore fail.
% =========================================================================

function VCG = calcula_y_dibuja_VCG(promedio,dibuja,lenta);
%VCG = calcula_VCG(promedio,dibuja);
%
%   dibuja: optional parameter, draws as
%           [puntos] -> sequence of points (start in red)
%           linea    -> continuous line   (start in red)
%           3d       -> 3D view (points, start in red)

if nargin < 2 % nargin = Number of function input arguments.
    dibuja = 'puntos'
end

[nsig,nsamp] = size(promedio); % number of rows and columns
if nsig == 12
    promedio_12 = promedio;
elseif nsig == 67
    promedio_12 = ders_estandar(promedio); % map from 67 rows to 12
else
    disp('Not appropriated format');
end

centered = 1;
VCG = idowerT(promedio_12); % with a 12xN matrix we can compute the VCG (3xN)

VCG = cerrar_bucle(VCG); % close the VCG loop

clf; % clear figure (analogous to clc, but for figures)
color = 'r';

if not(exist('lenta'))
    lenta = [1 length(VCG)]; % "lenta" is a row vector specifying which points to plot
    color = 'b';
end

switch dibuja % different branches depending on plotting mode
    case 'puntos' % 1 row x 3 columns layout
            subplot(1,3,1); plot(VCG(1,1:5:end),-VCG(2,1:5:end),'.'); hold on; plot(VCG(1,1),-VCG(2,1),'.r'); plot(VCG(1,end),-VCG(2,end),'.k'); xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X'); ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y'); % plot every 5 samples (dot-like appearance); also mark start / end points
            subplot(1,3,2); plot(VCG(1,1:5:end),VCG(3,1:5:end),'.'); hold on; plot(VCG(1,1),VCG(3,1),'.r'); plot(VCG(1,end),VCG(3,end),'.k');   xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X'); ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
            subplot(1,3,3); plot(VCG(3,1:5:end),-VCG(2,1:5:end),'.'); hold on; plot(VCG(3,1),-VCG(2,1),'.r'); plot(VCG(3,end),-VCG(2,end),'.k');  xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z'); ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
    case 'linea' % if linea=length(VCG), first and second plot are identical
            subplot(1,3,1); plot(VCG(1,:),-VCG(2,:)); hold on; plot(VCG(1,lenta(1):lenta(2)),-VCG(2,lenta(1):lenta(2)),color,'LineWidth',1); plot(VCG(1,1),-VCG(2,1),'.r'); plot(VCG(1,end),-VCG(2,end),'.k'); xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X'); ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y'); % plots every sample here
            subplot(1,3,2); plot(VCG(1,:),VCG(3,:)); hold on; subplot(1,3,2); plot(VCG(1,lenta(1):lenta(2)),VCG(3,lenta(1):lenta(2)),color,'LineWidth',1);  plot(VCG(1,1),VCG(3,1),'.r'); plot(VCG(1,end),VCG(3,end),'.k');   xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X'); ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
            subplot(1,3,3); plot(VCG(3,:),-VCG(2,:)); hold on; subplot(1,3,3); plot(VCG(3,lenta(1):lenta(2)),-VCG(2,lenta(1):lenta(2)),color,'LineWidth',1); plot(VCG(3,1),-VCG(2,1),'.r'); plot(VCG(3,end),-VCG(2,end),'.k');  xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z'); ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
    case '3d'
            plot3(VCG(1,1:10:end),VCG(2,1:10:end),VCG(3,1:10:end),'.') % 3D analogue of plot
            hold on;
            plot3(VCG(1,1),VCG(2,1),VCG(3,1),'or')
end

subplot(131), title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Frontal Plane')
            set(gca,'fontname','Times New Roman','FontSize',8)
            grid on
            grid minor
subplot(132), title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Transversal Plane')
            set(gca,'fontname','Times New Roman','FontSize',8)
            grid on
            grid minor
subplot(133), title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Sagittal Plane')
            set(gca,'fontname','Times New Roman','FontSize',8)
            grid on
            grid minor
