function ob = readTDMS(fid,index,SegInfo, samplestoread, startIndex)
%Using the file id (fid) and the index database, get the raw data.
%Returns the data in the ob structure.  The fields in the structure are the
%generic object names:
%   ob.Object3.data - raw data
%   ob.Object3.nsamples - number of samples
%
%   Note that not all of the objects in the index may not be in ob as it
%   contains only those objects which have raw data.

ob=[];
fnm=fieldnames(index);   %Get the object names
for kk=1:length(fnm)    %Loop through objects
    id=index.(fnm{kk});
    nsamples=sum(id.nValues.*id.multiplier);
    if id.rawdatacount>0  %Only work with channels with raw data
        cname=id.name;
        ob.(cname).nsamples=0;
        
        %Initialize the data matrix
        if id.dataType==32
            ob.(cname).data=cell(samplestoread,1);
        else
            ob.(cname).data=zeros(samplestoread,1);
        end
        samples = 0;
        for i = 1:length(id.nValues)
            samples = samples + id.nValues;
            if samples >= startIndex
                rr = i;
                break
            end
        end
        totalread = 0;
        while totalread < samplestoread && rr <= id.rawdatacount
            %Loop through each of the segments and read the raw data
            
            %Move to the raw data start position
            fseek(fid,id.datastartindex(rr)+id.rawdataoffset(rr),'bof');
            
            nvals=id.nValues(rr);
            totalread = totalread+nvals;
            segmentNum=index.(cname).index(rr);
            segInterleaved=SegInfo.SegInterleaved(segmentNum);
            
            if SegInfo.SegBigEndian(segmentNum)
                kTocEndian='b';
            else
                kTocEndian='l';
            end
            
            numChan=SegInfo.NumChan(segmentNum);
            
            if nvals>0  %If there is data in this segement
                
                switch id.dataType
                    
                    case 32		%String
                        %From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under the
                        %'Raw Data' description on page 4:
                        %String type channels are preprocessed for fast random access. All strings are concatenated to a
                        %contiguous piece of memory. The offset of the first character of each string in this contiguous piece
                        %of memory is stored to an array of unsigned 32-bit integers. This array of offset values is stored
                        %first, followed by the concatenated string values. This layout allows client applications to access
                        %any string value from anywhere in the file by repositioning the file pointer a maximum of three times
                        %and without reading any data that is not needed by the client.
                        data=cell(1,nvals*id.multiplier(rr));	%Pre-allocation
                        for mm=1:id.multiplier(rr)
                            StrOffsetArray=fread(fid,nvals,'uint32','l');
                            for dcnt=1:nvals
                                if dcnt==1
                                    StrLength=StrOffsetArray(dcnt);
                                else
                                    StrLength=StrOffsetArray(dcnt)-StrOffsetArray(dcnt-1);
                                end
                                data{1,dcnt+(mm-1)*nvals}=char(convertToText(fread(fid,StrLength,'uint8=>char','l'))');
                            end
                            if (id.multiplier(rr)>1)&&(id.skip(rr)>0)
                                fseek(fid,id.skip(rr),'cof');
                            end
                        end
                        cnt=nvals*id.multiplier(rr);
                        
                    case 68		%Timestamp
                        %data=NaN(1,nvals);	%Pre-allocation
                        data=NaN(1,nvals*id.multiplier(rr));
                        for mm=1:id.multiplier(rr)
                            dn=fread(fid,2*nvals,'uint64',kTocEndian);
                            tsec=dn(1:2:end)/2^64+dn(2:2:end);
                            data((mm-1)*nvals+1:(mm)*nvals)=tsec/86400+695422-4/24;
                            fseek(fid,id.skip(rr),'cof');
                        end
                        %{
						for dcnt=1:nvals
							tsec=fread(fid,1,'uint64')/2^64+fread(fid,1,'uint64');   %time since Jan-1-1904 in seconds
							%R. Seltzer: Not sure why '5/24' (5 hours) is subtracted from the time value.  That's how it was
							%coded in the original function I downloaded from MATLAB Central.  But I found it to be 1 hour too
							%much.  So, I changed it to '4/24'.
							data(1,dcnt)=tsec/86400+695422-5/24;	%/864000 convert to days; +695422 days from Jan-0-0000 to Jan-1-1904
							data(1,dcnt)=tsec/86400+695422-4/24;	%/864000 convert to days; +695422 days from Jan-0-0000 to Jan-1-1904
						end
                        %}
                        cnt=nvals*id.multiplier(rr);
                        
                    otherwise	%Numeric
                        matType=LV2MatlabDataType(id.dataType);
                        if strcmp(matType,'Undefined')  %Bad Data types catch
                            e=errordlg(sprintf('No MATLAB data type defined for a ''Raw Data Type'' value of ''%.0f''.',...
                                id.dataType),'Undefined Raw Data Type');
                            uiwait(e)
                            fclose(fid);
                            return
                        end
                        if (id.skip(rr)>0)
                            ntype=sprintf('%d*%s',nvals,matType);
                            [data,cnt]=fread(fid,nvals*id.multiplier(rr),ntype,id.skip(rr),kTocEndian);
                            if strcmp(matType,'uint8=>char')
                                data=convertToText(data);
                            end
                        else
                            % Added by Haench start
                            if  (id.dataType == 524300) || (id.dataType == 1048589) % complex CDB data
                                [data,cnt]=fread(fid,2*nvals*id.multiplier(rr),matType,kTocEndian);
                                data= data(1:2:end)+1i*data(2:2:end);
                                cnt = cnt/2;
                            else
                                [data,cnt]=fread(fid,nvals*id.multiplier(rr),matType,kTocEndian);
                            end
                            % Haench end
                            % Original: [data,cnt]=fread(fid,nvals*id.multiplier(rr),matType,kTocEndian);
                        end
                end
                
                %Update the sample counter
                if isfield(ob.(cname),'nsamples')
                    ssamples=ob.(cname).nsamples;
                else
                    ssamples=0;
                end
                if (cnt>0)
                    ob.(cname).data(ssamples+1:ssamples+cnt,1)=data;
                    ob.(cname).nsamples=ssamples+cnt;
                end
            end
            rr = rr+1;
        end
        
    end
    
end
end
