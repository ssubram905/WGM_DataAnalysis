function results = fromTdmsFile(fileinfo, varargin)
defaultsTime = 0;
defaulteTime = 20;
defaultFs = 1;
defaultScale = struct('m',1,'c',0);


p = inputParser;
p.FunctionName = 'fromTdmsFile';
addRequired(p,'fileinfo');
addOptional(p,'sTime',defaultsTime,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'eTime',defaulteTime,@(x) isnumeric(x) && isscalar(x) && (x > 0));
addOptional(p,'Fs',defaultFs,@(x) isnumeric(x) && isscalar(x) && (x > 0));
addOptional(p,'scale',defaultScale,@(x) isfield(x,'m') && isfield(x,'c'));
addOptional(p,'chNames',{'ai0','ai1'});
parse(p,fileinfo,varargin{:});

fileinfo = p.Results.fileinfo;
sTime = p.Results.sTime;
eTime = p.Results.eTime;
Fs = p.Results.Fs;
scale = p.Results.scale;
duration = eTime-sTime;
chNames = p.Results.chNames;

[convertedData,~,~,~,~]= convertTDMS(fileinfo,sTime,duration,Fs);
channelNames  = cell(1,length(convertedData.Data.MeasuredData));
channelNames(:) = {' '};
for i = 3:length( convertedData.Data.MeasuredData)
    channelNames{i} = convertedData.Data.MeasuredData(i).Property(5).Value;
end
indCh1 = contains(channelNames,chNames{1});
indCh2 = contains(channelNames,chNames{2});

% plot1 = detrend(convertedData.Data.MeasuredData(indCh1).Data*scale.m+scale.c);
plot1 = convertedData.Data.MeasuredData(indCh1).Data;
plot2 = detrend(convertedData.Data.MeasuredData(indCh2).Data*scale.m+scale.c);

time  = linspace(sTime,eTime,length(plot1))';
sIndex = 1;
eIndex = length(plot1);

[~,results.plotTitles{1}] = strtok(convertedData.Data.MeasuredData(indCh1).Name,'/');
results.plotTitles{1} = results.plotTitles{1}(2:end);
[~,results.plotTitles{2}] = strtok(convertedData.Data.MeasuredData(indCh2).Name,'/');
results.plotTitles{2} = results.plotTitles{2}(2:end);

results.sIndex = sIndex;
results.eIndex = eIndex;
results.time = time;
results.plot1 = plot1;
results.plot2 = plot2;
results.numModes = 1;
results.duration = duration;
end