function err = saveplots(data, path, varargin)
% plotdata - plots the selected data

defaultToggle = 'Off';

p = inputParser;
p.FunctionName = 'saveplots';
validString = @(x) strcmpi(x,'On') || strcmpi(x,'Off');
addRequired(p,'data');
addRequired(p,'path');
addOptional(p,'peaks',struct('plot1Peaks',struct('l',[]),...
    'plot2Peaks',struct('l',[])),  @(x) isstruct(x));
addOptional(p,'dtoggle',defaultToggle,validString);
addOptional(p,'ftoggle',defaultToggle,validString);
addOptional(p,'xlabel','Time [s]',@(x) ischar(x) || isstring(x));
addOptional(p,'ylabel_1','$\Delta \lambda$ [fm]',@(x) ischar(x) || isstring(x));
addOptional(p,'ylabel_2','$\Delta \lambda$ [fm]',@(x) ischar(x) || isstring(x));
addOptional(p,'xlim',[],@(x)  all(size(x) == [1 2]));
addOptional(p,'ylim',[],@(x)  all(size(x) == [2 2]));
addOptional(p,'sel',[]);

try
    parse(p, data, path,varargin{:});
catch ME
    err = ME;
    return;
end


data = p.Results.data;
path  = p.Results.path;
peaks  = p.Results.peaks;
dToggle = p.Results.dtoggle;
fToggle = p.Results.ftoggle;
xlabel = p.Results.xlabel;
ylabel_1 = p.Results.ylabel_1;
ylabel_2 = p.Results.ylabel_2;
xlim = p.Results.xlim;
ylim   = p.Results.ylim;
sel = p.Results.sel;

nm = data.modeNumber;
field = cell(2,1);

for i = 1:2
    if strcmpi(dToggle,'On')
        if strcmpi(fToggle,'On')
            field{i} = ['dt_fplot',num2str(i)];
        else
            field{i} = ['dt_plot',num2str(i)];
        end
    else
        if strcmpi(fToggle,'On')
            field{i} = ['fplot',num2str(i)];
        else
            field{i} = ['plot',num2str(i)];
        end
    end
    if isempty(data.(field{i})(:,nm))
        ME = MEException('plotdata:EmptyDataSet',...
            'Empty data set. Please check if you have set the data');
        err = ME;
        return
    end
end

try
    figurename = path(1:end-5);
    figurename = [figurename,'_timeTrace_',num2str(round(data.time(1))),...
        '_',num2str(round(data.time(end))),'s'];
    y1 = data.(field{1})(:,nm);
    y2  = data.(field{2})(:,nm);
    x = data.time;
  
    if ~isempty(sel)
        y1 = detrendSteps(y1,sel)';
    end
    
    fig = figure;
    fig.Units = 'centimeters';
    fig.Position = [2 2 19 15];
    fig.PaperUnits = 'centimeters';
    fig.PaperPosition = [2 2 19 15];
    
    subplot(2,1,1)
    plot(x,y1,'LineWidth',1)
    ax1 = gca;
    ax1.XGrid = 'on';
    ax1.YGrid = 'on';
    ax1.XTickLabel = [];
    if ~isempty(xlim)
        ax1.XLim = xlim;
    else
        ax1.XLim = [min(x) max(x)];
    end
    if ~isempty(ylim)
        ax1.YLim = ylim(1,:);
    else
        ax1.YLim = [min(y1)-5 max(y1)+5];
    end
    ax1.FontName = 'Helvetica';
    ax1.FontSize = 22;
    ax1.XLabel.Interpreter = 'latex';
    ax1.XLabel.FontSize = 24;
    ax1.YLabel.Interpreter = 'latex';
    ax1.YLabel.String = ylabel_1;
    ax1.YLabel.FontSize = 24;
    ax1.Units = 'centimeters';
    ax1.Position = [3.5 8.6 15.25 5.5];
%     ax.Position = [2.75 8 12 6];
    hold on
    if ~isempty(peaks.plot1Peaks.l)
        plotpeaks(gca(),data, peaks.plot1PeaksF,field{i});
        plotsubpeaks(gca(),data, peaks.plot1Peaks,field{i});
    end
    hold off
    
    subplot(2,1,2)
    plot(x,y2,'LineWidth',1)
    ax2 = gca;
    ax2.XGrid = 'on';
    ax2.YGrid = 'on';
    ax2.BoxStyle = 'back';
%     ax2.YTick = round(linspace(floor(min(y2)/10)*10,ceil(max(y2+5)/10)*10,3));
    if ~isempty(xlim)
        ax2.XLim = xlim;
    else
        ax2.XLim = [min(x) max(x)];
    end
    if ~isempty(ylim)
        ax2.YLim = ylim(2,:);
    else
        ax2.YLim = [min(y2)-5 max(y2)+5];
    end
    ax2.FontName = 'Helvetica';
    ax2.FontSize = 22;
    ax2.YLabel.Interpreter = 'latex';
    ax2.YLabel.String = ylabel_2;
    ax2.YLabel.FontSize = 24;
    ax2.XLabel.Interpreter = 'latex';
    ax2.XLabel.String = xlabel;
    ax2.XLabel.FontSize = 24;
    
    hold on
    if ~isempty(peaks.plot2Peaks.l)
        plotpeaks(gca(),data, peaks.plot2PeaksF,field{i});
        plotsubpeaks(gca(),data, peaks.plot2Peaks,field{i});
    end
    hold off

    ax2.Units = 'centimeters';
    ax2.Position = [3.5 2.2 15.25 5.75];
    ax1.YLabel.Position(1) = ax2.YLabel.Position(1);
    saveas(fig,figurename,'epsc');
    saveas(fig,figurename,'png');
    close(fig);
catch ME
    err = ME;
    return
end
err = [];
end

