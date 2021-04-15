function [results, errmsg] = getHeaders(fileProps)
% getHeaders - gets the comment and sets the sampling frequency

p = inputParser;
p.FunctionName = 'getHeaders';
addRequired(p,'fileProps');
parse(p,fileProps);

fileProps = p.Results.fileProps;

if strcmpi(fileProps.ext,'.txt')
    comment = fileProps.FileInfo.textdata;
    comment = comment(:,1);
    sindex = find(contains(comment,'Comment'));
    if ~isempty(sindex)
        eindex = find(or(contains(comment,'TresholdMethod'),contains(comment,'Time[s]')))-1;
        comment = comment(sindex:eindex);
    end
    t = fileProps.FileInfo.data(:,1);
    tTime = t(end);
    Fs = 1/mean(diff(t));
    
elseif strcmpi(fileProps.ext,'.tdms')
    Fs = getScanRate(fileProps.FileInfo.channelinfo);
    comment = getDescription(fileProps.FileInfo.channelinfo);
    samplesPerSegment = getsamplesPerSegment(fileProps.FileInfo.channelinfo);
    tTime = samplesPerSegment*fileProps.FileInfo.NumOfSeg/Fs;
else
    errmsg = {'File format not recognized. Please select the correct input file','File error'};
end
results.comment = comment;
results.Fs = Fs;
results.tTime = tTime;
errmsg = [];

end