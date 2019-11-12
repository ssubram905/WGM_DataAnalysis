function [results, err] = filterdata(data, field, varargin)
% filterdata -  filters the data depending on the window size and filter
%               type

defaultN = 5;

p = inputParser;
p.FunctionName = 'filterdata';
validnum = @(x) isnumeric(x) && isscalar(x);
addRequired(p,'data');
addRequired(p,'field');
addOptional(p,'filtertype','movingaverage',@(x) ischar(x) || isstring(x));
addOptional(p,'winsize',defaultN,validnum);
try
    parse(p, data ,field, varargin{:});
catch ME
    err = ME;
    return;
end


data = p.Results.data;
field = p.Results.field;
filtertype = p.Results.filtertype;
winsize = p.Results.winsize;
nm = length(data.(field{1})(1,:));

for j = 1: nm
    for i = 1:length(field)
        if length(data.(field{i})(:,j)) < winsize*3
            results.(['f',field{i}])(:,j) = data.(field{i})(:,j);
            ME = MException('filterData:dataSizeError',...
                'Data size less than window size');
            err = ME;
            return;
        elseif strcmpi(filtertype,'averaging')
            if ~mod(winsize,2)
                ME = MException('filterData:IncorrectWindowSize',...
                    'Window size must be odd for a golay filter');
                results = struct([]);
                err = ME;
                return;
            end
            results.(['f',field{i}])(:,j) = ...
                nanmean(reshape([data.(field{i})(:,j);...
                nan(mod(-numel(data.(field{i})(:,j)),winsize),1)],winsize,[]));
        elseif strcmpi(filtertype,'golay')
            if ~mod(winsize,2)
                ME = MException('filterData:IncorrectWindowSize',...
                    'Window size must be odd for a golay filter');
                results = struct([]);
                err = ME;
                return;
            end
            results.(['f',field{i}])(:,j) = ...
                sgolayfilt(data.(field{i})(:,j),1,winsize);
            
        elseif strcmpi(filtertype,'movingaverage')
            coeffs = ones(1, winsize)/winsize;
            results.(['f',field{i}])(:,j) = ...
                filtfilt(coeffs,1,data.(field{i})(:,j));
        elseif strcmpi(filtertype,'median')
            if ~mod(winsize,2)
                ME = MException('filterData:IncorrectWindowSize',...
                    'Window size must be odd for a golay filter');
                results = struct([]);
                err = ME;
                return;
            end
            results.(['f',field{i}])(:,j) = ...
                medfilt1(data.(field{i})(:,j),winsize);
            
        elseif strcmpi(filtertype,'Gaussian')
            ME = MException('filterData:functionUnavailable',...
                'Gaussian filtering currently unavailable');
            results = struct([]);
            err = ME;
            return
        else
            ME = MException('filterData:UnknownType',...
                'Filter type unknown, trype should be "golay","moving average","median" or "gaussian"');
            results = struct([]);
            err = ME;
            return
        end
    end
end
err = struct([]);
end