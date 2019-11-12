function err = plotdata(axes, data, varargin)
% plotdata - plots the selected data

defaultToggle = 'Off';

p = inputParser;
p.FunctionName = 'plotdata';
validString = @(x) strcmpi(x,'On') || strcmpi(x,'Off');
addRequired(p,'axes');
addRequired(p,'data');
addOptional(p,'dtoggle',defaultToggle,validString);
addOptional(p,'ftoggle',defaultToggle,validString);
addOptional(p,'xlims',[0 20],@(x) isnumeric(x) && length(x) == 2 );
addOptional(p,'ampThreshold',[0 0],@(x) isnumeric(x) );
try
    parse(p,axes, data ,varargin{:});
catch ME
    err = ME;
    return;
end



axes = p.Results.axes;
data = p.Results.data;
dToggle = p.Results.dtoggle;
fToggle = p.Results.ftoggle;
xlims = p.Results.xlims;
ampThreshold = p.Results.ampThreshold;
nm = data.modeNumber;
if nargin < 4
    xlims = [min(data.time) max(data.time)];
end

for i = 1:length(axes)
    if strcmpi(dToggle,'On')
        if strcmpi(fToggle,'On')
            field = ['dt_fplot',num2str(i)];
        else
            field = ['dt_plot',num2str(i)];
        end
    else
        if strcmpi(fToggle,'On')
            field = ['fplot',num2str(i)];
        else
            field = ['plot',num2str(i)];
        end
    end
    if isempty(data.(field)(:,nm))
        ME = MEException('plotdata:EmptyDataSet','Empty data set. Please check if you have set the data');
        err = ME;
        return
    end
    plot(axes(i),data.time, data.(field)(:,nm));
    hold(axes(i),'on');
    thresholdLine(:,1) = ones(length(data.time),1)*ampThreshold(i);
    thresholdLine(:,2) = ones(length(data.time),1)*-ampThreshold(i);
    plot(axes(i),data.time, thresholdLine,'-.');
    hold(axes(i),'off');
    axes(i).YLim = [min(data.(field)(:,nm))-5 max(data.(field)(:,nm))+10];
    axes(i).XLim = xlims;
end
err = [];
end