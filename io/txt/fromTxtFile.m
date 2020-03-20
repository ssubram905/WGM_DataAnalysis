function results = fromTxtFile(fileinfo, varargin)
% Function to read data from a text file

defaultsTime = 0;
defaulteTime = 20;
defaultFs = 1;

p = inputParser;
p.FunctionName = 'fromTxtFile';
addRequired(p,'fileinfo');
addOptional(p,'sTime',defaultsTime,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'eTime',defaulteTime,@(x) isnumeric(x) && isscalar(x) && (x > 0));
addOptional(p,'Fs',defaultFs,@(x) isnumeric(x) && isscalar(x) && (x > 0));
parse(p,fileinfo,varargin{:});

fileinfo = p.Results.fileinfo;
sTime = p.Results.sTime;
eTime = p.Results.eTime;
Fs = p.Results.Fs;

s = size(fileinfo.data);
ndata = (s(2)-1)/2;

sIndex = ceil(sTime*Fs);
if ~sIndex
    sIndex = 1;
end
eIndex = floor(eTime*Fs);
if eIndex > length(fileinfo.data)
    eIndex = length(fileinfo.data);
end
time = fileinfo.data(sIndex:eIndex,1);
eTime = time(end);
plot1 = zeros(eIndex-sIndex+1,ndata);
plot2 = zeros(eIndex-sIndex+1,ndata);
for i = 1:ndata   
    plot1(:,i) = (fileinfo.data(sIndex:eIndex,i+1) - min(fileinfo.data(sIndex:eIndex,i+1)));
    plot2(:,i) = fileinfo.data(sIndex:eIndex,i+ndata+1);
    if ~contains(fileinfo.textdata(end),'[fm]')
        plot1(:,i) = plot1(:,i)*1e6;
        plot2(:,i) = plot2(:,i)*1e6;
    end
end

results.sIndex = 1;
results.eIndex = length(plot1);
results.time = time;
results.plot1 = plot1;
results.plot2 = plot2;
results.numModes = ndata;
results.eTime = eTime;
results.sTime = sTime;
results.duration = eTime-sTime;
results.plotTitles{1} = 'lambda';
results.plotTitles{2} = 'fwhm';
end