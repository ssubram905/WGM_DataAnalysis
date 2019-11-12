function [results, err] = detrendData(data,field, varargin)
%detrendData - detrends the input data using a N point moving average filter

defaultN = 101;

p = inputParser;
p.FunctionName = 'detrendData';
validnum = @(x) isnumeric(x) && isscalar(x);
addRequired(p,'data');
addRequired(p,'field');
addOptional(p,'winsize',defaultN,validnum);

try
    parse(p, data, field, varargin{:});
catch ME
    err = ME;
    return;
end

data = p.Results.data;
field = p.Results.field;
winsize = p.Results.winsize;
Fs = data.Fs;
nm = length(data.(field{1})(1,:));


for j = 1:nm
    if length(data.plot1(:,j)) > Fs/100*winsize
        ds =  ceil(Fs/1000);
    else
        ds = 1;
    end
    try
        for i = 1:length(field)
            if length(data.(field{i})(:,j)) < winsize*3
                results.(['dt_',field{i}])(:,j) = detrend(data.(field{i})(:,j));
            else
                results.(['dt_',field{i}])(:,j) = data.(field{i})(:,j) - ...
                    sgolayfilt(data.(field{i})(:,j),1,winsize);
                %             coeffs = ones(1, winsize)/winsize;
                %             fData = filtfilt(coeffs,1,downsample(data.(field{i})(:,nm),ds));
                %             x = 1:ds:length(data.(field{i})(:,nm));
                %             xq = 1:length(data.(field{i})(:,nm));
                %             results.(['dt_',field{i}])(:,nm) = data.(field{i})(:,nm)- ...
                %                 interp1(x,fData,xq,'linear','extrap')';
            end
        end
    catch ME
        results = [];
        err = ME;
        return
    end
end
err = [];
end