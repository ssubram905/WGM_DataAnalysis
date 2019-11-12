    function samplesPerSegment = getsamplesPerSegment(channelinfo)
    fnm=fieldnames(channelinfo);
    for kk = 1:length(fnm)
        if isfield(channelinfo.(fnm{kk}),'PropertyInfo')
            for jj = 1:length(channelinfo.(fnm{kk}).PropertyInfo)
                if strcmpi(channelinfo.(fnm{kk}).PropertyInfo(jj).Name, 'wf_samples')
                    fld = channelinfo.(fnm{kk}).PropertyInfo(jj).FieldName;
                    samplesPerSegment = channelinfo.(fnm{kk}).(fld).value;
                    return
                end
            end
        end
    end
    end