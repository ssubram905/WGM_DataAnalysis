function savetomat(filepath, datatosave,varnames,Fs,gdur,comment)
%savetomat - saves the peak data to a mat file
names = fieldnames(datatosave);
for i = 1:length(varnames)
    varnames{i} = varnames{i}(~isspace(varnames{i}));
end
for i = 1:length(names)
    if contains(names{i},'plot1')
        oStruct.([varnames{1},'_',num2str(ceil(i/2))]) = datatosave.(names{i});
    elseif contains(names(i),'plot2')
        oStruct.([varnames{2},'_',num2str(i/2)]) = datatosave.(names{i});
    else
        oStruct.(names{i}) = datatosave.(names{i});
    end
end
oStruct.daqProps.Fs = Fs;
oStruct.daqProps.GroupingThreshold = gdur;
oStruct.comment = comment;
save([filepath,'Peaks.mat'],'-struct','oStruct');
end