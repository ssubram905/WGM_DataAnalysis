function [peakdata, err] = findpeaksindata(ydata, varargin)
% finpeaksindata - find the peaks in the data using finpeaks with the given
%                  threshold and max peak width
%
% see also findpeaks

p = inputParser;
p.FunctionName = 'findpeaksindata';
validnum = @(x) isnumeric(x) && isscalar(x);
addRequired(p,'ydata',@(x) (~isempty(x)));
addOptional(p,'xdata',[],@(x) isnumeric(x));
addOptional(p,'sdev',[]);
addOptional(p,'N',5);
addOptional(p,'ampThreshold',6,validnum);
addOptional(p,'nflag','Off',@(x) ischar(x) && (strcmpi(x,'On') ||...
    strcmpi(x,'Off')));
peakdata = struct('h',[],'l',[],'w',[],'p',[],'area',[]);

try
    parse(p, ydata ,varargin{:});
catch ME
    err = ME;
    return
end


ydata = p.Results.ydata;
if isempty(p.Results.xdata)
    xdata = 1:length(ydata);
else
    xdata = p.Results.xdata;
end
sdev = p.Results.sdev;
if isempty(sdev)
    B = floor(length(tmpdata)/10)*10;
    rslambda = reshape(tmpdata(1:B),[10 B/10]);
    sdev = std(rslambda);
    sdev = mean(nonzeros(sdev));
end
N = p.Results.N;
ampThreshold = p.Results.ampThreshold;
nflag = p.Results.nflag;

if strcmpi(nflag,'On')
    ydata = -ydata;
end

delT = mean(diff(xdata));
try
    [pks,locs,w,p] = findpeaks(ydata,'MinPeakHeight',ampThreshold,'MinPeakProminence',sdev);
    if ~isempty(locs)
        s = zeros(1,length(locs));
        for i = 1:length(locs)
            if locs(i) < N
                N = locs(i) -1;
            end
            s(i) = std(ydata(locs(i)-N:locs(i)+N));
            if s(i) >  sdev
                peakdata.h = [peakdata.h;pks(i)];
                peakdata.p = [peakdata.p;p(i)];
                peakdata.l = [peakdata.l;xdata(locs(i))];
                peakdata.w = [peakdata.w;w(i)*delT];
                sindex = floor(locs(i)-w(i)/2);
                eindex = floor(locs(i)+w(i)/2);
                area = trapz(xdata(sindex:eindex),ydata(sindex:eindex));
                peakdata.area = [peakdata.area;area];
            end
        end
    end
catch ME
    err = ME;
    return
end

if strcmpi(nflag,'On')
    peakdata.p = -peakdata.p;
    peakdata.h = -peakdata.h;
end
err = [];
end