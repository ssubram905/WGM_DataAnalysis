function plot2subplots(data1, data2, time, path, xlabel, ylabel_1, ylabel_2)


figurename = path(1:end-5);
figurename = [figurename,'_timeTrace_',num2str(round(time(1))),...
              '_',num2str(round(time(end))),'s'];
y1 = data1;
y2  = data2;
x = time;

fig = figure;
fig.Units = 'centimeters';
fig.Position = [2 2 19 15];
fig.PaperUnits = 'centimeters';
fig.PaperPosition = [2 2 19 15];

subplot(2,1,1)
plot(x,y1,'LineWidth',1)
ax = gca;
ax.XTickLabel = [];
ax.XLim = [min(x) max(x)];
ax.YLim = [min(y1)-5 max(y1)+10];
ax.FontName = 'Helvetica';
ax.FontSize = 16;
ax.XLabel.Interpreter = 'latex';
ax.XLabel.FontSize = 18;
ax.YLabel.Interpreter = 'latex';
ax.YLabel.String = ylabel_1;
ax.YLabel.FontSize = 18;
ax.Units = 'centimeters';
ax.Position = [2.75 8 16 6];


subplot(2,1,2)
plot(x,y2,'LineWidth',1)
ax = gca;
ax.BoxStyle = 'back';
ax.YTick = round(linspace(floor(min(y2)/10)*10,ceil(max(y2+5)/10)*10,3));
ax.XLim = [min(x) max(x)];
ax.YLim = [min(y2)-5 max(y2)+10];
ax.FontName = 'Helvetica';
ax.FontSize = 16;
ax.YLabel.Interpreter = 'latex';
ax.YLabel.String = ylabel_2;
ax.YLabel.FontSize = 18;
ax.XLabel.Interpreter = 'latex';
ax.XLabel.String = xlabel;
ax.XLabel.FontSize = 18;

ax.Units = 'centimeters';
ax.Position = [2.75 2 16 6];
saveas(fig,figurename,'epsc');
saveas(fig,figurename,'emf');
close(fig);
end

