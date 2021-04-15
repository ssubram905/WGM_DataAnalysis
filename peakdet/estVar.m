function [results, err]= estVar(data,varargin)
% estVar - gets the mean standard deviation of the selected data set
%           sets the variables peakFinderProps.sDevLambda, peakFinderProps.sDevFwhm
% V - Length of data to find std
% M - number of interations
% k - threshold
defaultToggle = 'Off';
p = inputParser;
p.FunctionName = 'estVar';
validString = @(x) strcmpi(x,'On') || strcmpi(x,'Off');
addRequired(p,'data');
addOptional(p,'V',4,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'M',4,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'kappa',6,@(x) isnumeric(x) && isscalar(x) && (x >= 0));
addOptional(p,'ftoggle',defaultToggle,validString);

try
    parse(p,data,varargin{:});
    data = p.Results.data;
    V = p.Results.V;
    M = p.Results.M;
    kappa = p.Results.kappa;
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
        y = data.(field)(:,nm);
        ofield = ['sdev',field(end-4:end)];
        Im = V/2+1:length(y)-V/2;
        for j = 1:M
            L = zeros(length(Im),1);
            Fm = zeros(length(Im),1);
            for k = 1:length(Im)
                selRange = Im(k)-V/2:Im(k)+V/2;
                L(k) = var(y(selRange));
            end
            Lm = mean(L);
            Fm(L > kappa*Lm) = 1;
            Im = Im(Fm==0);
        end
        results.(ofield) = sqrt(Lm);
    end
catch ME
    err = ME;
    results = struct([]);
    return
end
err = [];

end