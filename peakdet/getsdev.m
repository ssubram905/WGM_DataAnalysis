function [results, err] = getsdev(data, varargin)
% getsdev - gets the mean standard deviation of the selected data set
%           sets the variables peakFinderProps.sDevLambda, peakFinderProps.sDevFwhm
defaultToggle = 'Off';
p = inputParser;
p.FunctionName = 'getsdev';
validString = @(x) strcmpi(x,'On') || strcmpi(x,'Off');
addRequired(p,'data');
addOptional(p,'N',10,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'ftoggle',defaultToggle,validString);

try
    parse(p,data,varargin{:});    
    data = p.Results.data;
    N = p.Results.N;    
    nm = data.modeNumber;
    fToggle = p.Results.ftoggle;

    names = fieldnames(data);
    if strcmpi(fToggle,'On')
        search_term = 'dt_fplot';
    else
        search_term = 'dt_plot';
    end
    fnames = find(contains(names,search_term));
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