function [results, errmsg] = getData(fileProps, varargin)
% getData - gets the input data from a text or tdms file
%           sets the variables time, plot1, plot2 and comment

defaultsTime = 0;
defaulteTime = 20;
defaultFs = 1;

p = inputParser;
p.FunctionName = 'getData';
addRequired(p,'fileProps');
addOptional(p,'sTime',defaultsTime,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'eTime',defaulteTime,@(x) isnumeric(x) && isscalar(x) && (x > 0));
addOptional(p,'Fs',defaultFs,@(x) isnumeric(x) && isscalar(x) && (x > 0));
parse(p,fileProps,varargin{:});

fileProps = p.Results.fileProps;
sTime = p.Results.sTime;
eTime = p.Results.eTime;
Fs = p.Results.Fs;


if strcmpi(fileProps.ext,'.txt')
    results = fromTxtFile(fileProps.FileInfo, sTime,eTime,Fs);
elseif strcmpi(fileProps.ext,'.tdms')
    results = fromTdmsFile(fileProps.FileInfo,sTime,eTime,Fs,fileProps.FileInfo.scale);
else
    errmsg = {'File format not recognized. Please select the correct input file','File error'};
end
errmsg = [];
end