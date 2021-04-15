function  [tstep,height,wstep, ME] = stepDetect(hAxes, y, time, steps)

% function to detect the steps

sP = steps.startPoint;
lO = steps.leftOffset;
lI = steps.leftInterval;
rI = steps.rightInterval;
rO = steps.rightOffset;

tstep = [];
height = [];
wstep = [];
ME = [];
try
    yL = y(sP-lO-lI+1: sP-lO);
    xL = time(sP-lO-lI+1: sP-lO);
    yR = y(sP+rO:sP+rO+rI+1);
    xR = time(sP+rO:sP+rO+rI+1);
    
    pL = polyfit(xL,yL,1);
    yLfit = polyval(pL,xL);
    
    pR = polyfit(xR,yR,1);
    yRfit = polyval(pR,xR);
    
    stepHeight = yRfit(1) - yLfit(end);
    
    tstep = time(sP-lO);
    wstep = time(sP+rO)-time(sP-lO);
    height = stepHeight;
    
    plot(hAxes,time,y);
    hold(hAxes,'on');
    % plot trend for each region
    plot(hAxes,time(sP+rO:sP+rO+rI+1),y(sP+rO:sP+rO+rI+1),'LineWidth',2);
    plot(hAxes,time(sP-lO-lI+1: sP-lO),y(sP-lO-lI+1: sP-lO),'LineWidth',2);
    hold(hAxes,'off');
    
catch ME
    
end

end
