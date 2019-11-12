function [peaks, err] = grouppeaks(data, varargin)
% grouppeaks - groups the peak data into clusters based on the duration threshold

p = inputParser;
p.FunctionName = 'grouppeaks';
validnum = @(x) isnumeric(x) && isscalar(x);
addRequired(p,'data',@(x) isstruct(x) && isfield(x,'h') && ...
    isfield(x,'l') && isfield(x,'w') && isfield(x,'p') && isfield(x,'area'));
addOptional(p,'durationThreshold',0.3,validnum);
peaks = struct([]);
try
    parse(p, data, varargin{:});
catch ME
    err = ME;
    return;
end

data = p.Results.data;
durationThreshold = p.Results.durationThreshold;

distLocs = diff(data.l);
peaks(1).ls = data.l(1);
peaks(1).ws = data.w(1);
peaks(1).duration = data.w(1);
peaks(1).hs = data.h(1);
peaks(1).area = data.area(1);
peaks(1).totalarea = sum(peaks(1).area);
count = 1;
try
    for i = 2:length(data.l)
        if distLocs(i-1) <= durationThreshold
            peaks(count).ls = [peaks(count).ls; data.l(i)];
            peaks(count).ws = [peaks(count).ws; data.w(i)];
            peaks(count).area = [peaks(count).area; data.area(i)];
            peaks(count).duration = sum(peaks(count).ws);
            peaks(count).totalarea = sum(peaks(count).area);
            peaks(count).hs = [peaks(count).hs; data.h(i)];
        else
            count = count+1;
            peaks(count).ls = data.l(i);
            peaks(count).ws = data.w(i);
            peaks(count).area = data.area(i);
            peaks(count).duration = data.w(i);
            peaks(count).totalarea = data.area(i);
            peaks(count).hs = data.h(i);
        end
    end
for i = 1:length(peaks)
    peaks(i).l = mean(peaks(i).ls);
    peaks(i).w = abs(peaks(i).l-peaks(i).ls(1)+peaks(i).ws(1));
    peaks(i).h = max(peaks(i).hs);
end
catch ME
    err = ME;
    return;
end
err = [];
end