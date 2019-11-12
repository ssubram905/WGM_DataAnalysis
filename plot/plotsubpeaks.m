function err = plotsubpeaks(axes, data, peaks, field)
% plotpeaks - plots the peaks data over the plotted data

p = inputParser;
p.FunctionName = 'plotsubpeaks';
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
% yfit = zeros(length(ydata),1);
% for i = 1:length(peaks.l)
%     yfit = yfit + peaks.h(i)*gaussian(xdata,peaks.l(i),peaks.w(i));
% end
for i = 1:length(peaks)
    plot(axes,peaks(i).l,peaks(i).h,'v','Linewidth',2)
end
hold(axes,'off');
catch ME
    err = ME;
    return
end
err = [];
end