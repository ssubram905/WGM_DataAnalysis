function plotpeakinfo(axes, data_struct, data, field, C )
% plotpeakinfo - plots the peak info height and width in separate plots
%                data over the plotted data

p = inputParser;
p.FunctionName = 'plotpeakinfo';
addRequired(p,'axes');
addRequired(p,'data_struct');
addRequired(p,'data');
addRequired(p,'field');
parse(p,axes, data_struct, data , field);

axes = p.Results.axes;
data_struct = p.Results.data_struct;
data = p.Results.data;
field = p.Results.field;
% markers = ['v','s','d','o','^','>','<','+','*','p','<','.'];

for i = 1:length(axes)
    hold(axes(i),'on');
    for j = 1:length(data_struct.(data{i}))
        plot(axes(i),data_struct.(data{i})(j).l, ...
            data_struct.(data{i})(j).(field),'v','Color',C);
    end
    hold(axes(i),'off');
end

end