function [results, err] = getsdev(data, varargin)
% getsdev - gets the mean standard deviation of the selected data set
%           sets the variables peakFinderProps.sDevLambda, peakFinderProps.sDevFwhm

p = inputParser;
p.FunctionName = 'getsdev';
addRequired(p,'data');
addOptional(p,'N',10,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
try
    parse(p,data,varargin{:});    
    data = p.Results.data;
    N = p.Results.N;    
    nm = data.modeNumber;
    
    names = fieldnames(data);
    fnames = find(contains(names,'dt_plot'));
    for i = 1:length(fnames)
        field = names{fnames(i)};
        tmpdata = data.(field)(:,nm);
        ofield = ['sdev',field(4:end)];
        if nargin < 2
            results.(ofield) = std(tmpdata);
        else
            B = floor(length(tmpdata)/N)*N;
            rslambda = reshape(tmpdata(1:B),[N B/N]);
            s = std(rslambda);
            results.(ofield) = mean(nonzeros(s));
        end
    end
catch ME
    err = ME;
    results = struct([]);
    return
end
err = [];

end