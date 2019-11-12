function err = saveplots2(UIAxes, path)
% plotdata - plots the selected data

p = inputParser;
p.FunctionName = 'saveplots2';
addRequired(p,'axes');
addRequired(p,'path');
try
    parse(p, UIAxes, path);
catch ME
    err = ME;
    return;
end


UIAxes = p.Results.axes;
path  = p.Results.path;

try
    h = figure;
%     h.Visible = 'off';
    x = UIAxes.XAxis.Parent.Children.XData;
    for i = 1:length(UIAxes.XAxis.Parent.Children)
       y(i,:) = UIAxes.XAxis.Parent.Children.YData;
    end
    plot(x,y)
    h.CurrentAxes.YLabel.String = UIAxes.YLabel.String;
    h.CurrentAxes.YLabel.FontSize = UIAxes.YLabel.FontSize;
    h.CurrentAxes.XLabel.String = UIAxes.XLabel.String;
    h.CurrentAxes.XLabel.FontSize = UIAxes.XLabel.FontSize;
    h.CurrentAxes.Title.String = UIAxes.Title.String;
    h.CurrentAxes.Title.FontSize = UIAxes.Title.FontSize;
    h.CurrentAxes.XLim = UIAxes.XLim;
    h.CurrentAxes.YLim = UIAxes.YLim;
    saveas(h,path,'epsc')
%     savefig(h,SaveName)
    delete(h)
catch ME
    err = ME;
    return
end
err = [];
end

