function err = plotpeaks(axes, data, peaks, field)
% plotpeaks - plots the peaks data over the plotted data

p = inputParser;
p.FunctionName = 'plotpeaks';
addRequired(p,'axes');
addRequired(p,'data');
addRequired(p,'peaks');
addRequired(p,'field',@(x) ischar(x));
parse(p,axes, data ,peaks, field);

axes = p.Results.axes;
data = p.Results.data;
peaks = p.Results.peaks;
field = p.Results.field;
nm = data.modeNumber;

try
    xdata = data.time;
    ydata = data.(field)(:,nm);
    
    hold(axes,'on');
    yfit = zeros(length(ydata),1);
    % for i = 1:length(peaks)
    %     yfit = yfit + peaks(i).h*gaussian(xdata,peaks(i).l,peaks(i).w);
    % end
    for i = 1:length(peaks)
        sindex = find(xdata >= peaks(i).ls(1)-peaks(i).ws(1),1,'first');
        eindex = find(xdata >= peaks(i).ls(end)+peaks(i).ws(end),1,'first')-1;
        yfit(sindex:eindex)= peaks(i).h*ones(eindex-sindex+1,1);
    end
    plot(axes,xdata,yfit,'r','Linewidth',2)
    
    hold(axes,'off');
catch ME
    err = ME;
    return
end
err = [];
end