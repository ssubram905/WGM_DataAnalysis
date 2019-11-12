function [peakdata, err] = findpeaksindata2(ydata, varargin)
% finpeaksindata - find the peaks in the data using finpeaks with the given
%                  threshold and max peak width
%
% see also findpeaks

p = inputParser;
p.FunctionName = 'findpeaksindata2';
validnum = @(x) isnumeric(x) && isscalar(x);
addRequired(p,'ydata',@(x) (~isempty(x)));
addOptional(p,'xdata',[],@(x) isnumeric(x));
addOptional(p,'slopeThreshold',1e-4,validnum);
addOptional(p,'ampThreshold',6,validnum);
addOptional(p,'smoothwidth',101,validnum);
addOptional(p,'peakgroup',200,validnum);
addOptional(p,'smoothtype',3,validnum);
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
ampThreshold = p.Results.ampThreshold;
slopeThreshold = p.Results.slopeThreshold;
smoothwidth = p.Results.smoothwidth;
smoothtype = p.Results.smoothtype;
peakgroup = p.Results.peakgroup;
nflag = p.Results.nflag;

if strcmpi(nflag,'On')
    ydata = -ydata;
end

try
    fpb = findpeaksG(xdata,ydata,slopeThreshold,ampThreshold,smoothwidth,...
        peakgroup,smoothtype);
catch ME
    err = ME;
    return
end
if any(fpb(:,2))
    peakdata.h = fpb(:,3);
    peakdata.p = fpb(:,3);
    peakdata.l = fpb(:,2);
    peakdata.w = abs(fpb(:,4));
    peakdata.area = fpb(:,5);
end
if strcmpi(nflag,'On')
    peakdata.h = -peakdata.h;
end
err = [];
end