clear
clc

time = [];
lambda = [];
fwhm = [];


fname = dir('Analyse19Feb18Meas*Ana0.txt'); % open the first file for each measurement
n1 = {fname.name};
z = regexp(n1,'(?<=Analyse31Oct19Meas3Ana)\d*(?=\.txt)','match');
z1 = str2double(cat(1,z{:}));
[~,ii] = sort(z1);
fname = fname(ii);

for j = 1:length(fname)
    fid = fopen(fname(1).name(8:end),'wt'); % open file for wirting output    
    [comment, data, m] = extractDataFromAnalyzedFiles(1,fname(j).name);
    if isempty(time)
        time = data.time;
        lambda = data.lambda;
        fwhm = data.fwhm;
    else
        [data.lambda,lambda] = combineDifferentMatrices(data.lambda,lambda);
        lambda = [lambda;data.lambda];
        [data.fwhm,fwhm] = combineDifferentMatrices(data.fwhm,fwhm);
        fwhm = [fwhm;data.fwhm];
        data.time = data.time(1:length(data.lambda(:,1)));
        time = [time; data.time + time(end)+ mean(diff(time))];

    end

end
for k = 1:length(m.textdata(:,1))-1
    fprintf(fid,'%s\n',cell2mat(m.textdata(k)));
end
S = sprintf('%s     ',m.textdata{k+1,:});
S = strrep(S,'Points','nm');
fprintf(fid,'%s\n',S);
fclose(fid);
dlmwrite(fname(1).name(8:end),[time,lambda,fwhm],...
    'precision','%0.10f','delimiter','\t','newline', 'pc','-append');
