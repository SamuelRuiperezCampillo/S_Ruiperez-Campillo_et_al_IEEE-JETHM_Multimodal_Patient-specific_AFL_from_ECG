% =========================================================================
%  dibuja_VCG.m  --  Third-party code
%
%  Source: Internal plotting utility of the EP Analytics Lab / ITACA / UPV group.
%  Bundled in this repository for reproducibility. See THIRD_PARTY.md.
%  Do NOT modify.
% =========================================================================

function dibuja_VCG(VCG,dimension,modo,v,hold_options);
%dibuja_VCG(VCG,dimension,modo,v);
%
%   dimension: 2d/3d
%   modo:      linea/puntos
%   pos_v:     intervals with slow conduction

if nargin>3
    N_intervalos = size(v); % size of the number of intervals
    N_intervalos = N_intervalos(1); % keep number of rows
end

color = 'rkg';

if nargin<5
   clf; %clear figure
   hold_options = 'clear';
end

switch dimension
    case '2d'
        switch modo
            case 'linea'
                subplot(1,3,1);
                    hold off;
                    plot(VCG(1,:),-VCG(2,:));
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
                    title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Frontal Plane');
                    hold on;
                    plot(VCG(1,1),-VCG(2,1),'.r');
                    plot(VCG(1,end),-VCG(2,end),'.k');
                                set(gca,'fontname','Times New Roman','FontSize',8)
                                grid on
                                grid minor
                subplot(1,3,2);
                    hold off;
                    plot(VCG(1,:),VCG(3,:));
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
                    title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Transversal Plane');
                    hold on;
                    plot(VCG(1,1),VCG(3,1),'.r');
                    plot(VCG(1,end),VCG(3,end),'.k');
                                set(gca,'fontname','Times New Roman','FontSize',8)
                                grid on
                                grid minor
                subplot(1,3,3);
                    hold off;
                    plot(VCG(3,:),-VCG(2,:));
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
                    title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Sagittal Plane');
                    hold on;
                    plot(VCG(3,1),-VCG(2,1),'.r');
                    plot(VCG(3,end),-VCG(2,end),'.k');
                                set(gca,'fontname','Times New Roman','FontSize',8)
                                grid on
                                grid minor
                if nargin==4
                    for i =1:N_intervalos
                    subplot(1,3,1);
                        hold on;
                        plot(VCG(1,v(i,1):v(i,2)),-VCG(2,v(i,1):v(i,2)),color(mod(i-1,3)+1),'LineWidth',2); % plots only the requested intervals
                                set(gca,'fontname','Times New Roman','FontSize',8)
                    subplot(1,3,2);
                        hold on;
                        plot(VCG(1,v(i,1):v(i,2)),VCG(3,v(i,1):v(i,2)),color(mod(i-1,3)+1),'LineWidth',2);
                                set(gca,'fontname','Times New Roman','FontSize',8)
                    subplot(1,3,3);
                        hold on;
                        plot(VCG(3,v(i,1):v(i,2)),-VCG(2,v(i,1):v(i,2)),color(mod(i-1,3)+1),'LineWidth',2);
                                set(gca,'fontname','Times New Roman','FontSize',8)
                    end
                end
            case 'puntos'
                subplot(1,3,1);
                    plot(VCG(1,1:5:end),-VCG(2,1:5:end),'.');
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
                    title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Frontal Plane');
                                set(gca,'fontname','Times New Roman','FontSize',8)
                                grid on
                                grid minor
                subplot(1,3,2); plot(VCG(1,1:5:end),VCG(3,1:5:end),'.');
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
                    title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Transversal Plane');
                                set(gca,'fontname','Times New Roman','FontSize',8)
                                grid on
                                grid minor
                subplot(1,3,3);
                    plot(VCG(3,1:5:end),-VCG(2,1:5:end),'.');
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
                    title('\fontsize{12} \color[rgb]{0 .5 .5} \fontname{Georgia} Sagittal Plane');
                                set(gca,'fontname','Times New Roman','FontSize',8)
                                grid on
                                grid minor
        end

    case '3d'
        if strcmp(hold_options,'hold')
            hold on;
        end
        switch modo
            case 'linea'
                plot3(VCG(1,:),VCG(3,:),-VCG(2,:));
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
                    zlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
                    title('\fontsize{16} \color[rgb]{0 .5 .5} \fontname{Georgia} \bf 3D-Line Representation of the Average VCG')
                    set(gca,'fontname','Times New Roman','FontSize',10)
                    grid on
                    grid minor
            case 'puntos'
                plot3(VCG(1,1:5:end),VCG(3,1:5:end),-VCG(2,1:5:end),'.');
                    xlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf X');
                    ylabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Y');
                    zlabel('\fontsize{12} \fontname{Times New Roman} \color[rgb]{0 .5 .5} \bf Z');
                    title('\fontsize{16} \color[rgb]{0 .5 .5} \fontname{Georgia} \bf 3D-Dot Representation of the Average VCG')
                    set(gca,'fontname','Times New Roman','FontSize',10)
                    grid on
                    grid minor
        end

end
