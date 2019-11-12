function [x, p, f, yfit] = probDist(intervalMS, DelT,ax)
% probabilityDist - calculates the rate distribution for the given interval
%                   array. This function provides an one parameter
%                   exponential fit and returns the fitted rate.
%                   intervalMS = diff(locs); The time between each arrival

x = (1:round(max(intervalMS)/DelT))*DelT;
p = zeros(length(x),1);
for i = 1:length(x)  % Calculate prob of zero events in a time interval
    tmp = find(intervalMS >= i*DelT);
    p(i) = (length(tmp))/length(intervalMS);
end
%p = p/sum(p);
% fit settings
func = fittype( 'exp(-b*x)');  % fit function
options = fitoptions('exp1');
options.StartPoint = 0;
options.Lower = 0;
options.Upper = Inf;
f = fit(x.',p,func,options);
yfit = feval(f,x);

plot(ax,x,p)
hold(ax,'on')
plot(ax,x,yfit,'LineWidth',2)
hold(ax,'off')

end
