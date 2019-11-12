function  [tstep,height, ME] = stepDetect(hAxes, y, time, steps)

% function to detect the steps

sP = steps.startPoint;
lO = steps.leftOffset;
lI = steps.leftInterval;
rI = steps.rightInterval;
rO = steps.rightOffset;

tstep = [];
height = [];
ME = [];
try
    stepHeight = mean(y(sP+rO:sP+rO+rI+1)) - mean(y(sP+lO-lI+1: sP+lO));
    
    tstep = time(sP+lO);
    height = stepHeight;
    
    plot(hAxes,time,y);
    hold(hAxes,'on');
    % plot trend for each region
    plot(hAxes,time(sP+rO:sP+rO+rI+1),y(sP+rO:sP+rO+rI+1),'LineWidth',2);
    plot(hAxes,time(sP+lO-lI+1: sP+lO),y(sP+lO-lI+1: sP+lO),'LineWidth',2);
    hold(hAxes,'off');
    
catch ME
    
end

end
