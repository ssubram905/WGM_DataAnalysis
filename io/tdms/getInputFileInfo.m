function [FileInfo ] = getInputFileInfo(varargin)


p=inputParser();

p.addRequired('SaveConvertedFile',@(x) islogical(x)||(ismember(x,[0,1])));
p.addOptional('filename','',@(x) iscell(x)||exist(x,'file'));
p.parse(varargin{:});

filename=p.Results.filename;
FileInfo.SaveConvertedFile=p.Results.SaveConvertedFile;

if isempty(filename)
    
    %Prompt the user for the file
    [filename,pathname]=uigetfile({'*.tdms','All Files (*.tdms)'},'Choose a TDMS File');
    if filename==0
        return
    end
    filename=fullfile(pathname,filename);
end

%
% if iscell(filename)
%     %For a list of files
%     infilename=filename;
% else
%     infilename=cellstr(filename);
% end



if ~exist(filename,'file')
    e=errordlg(sprintf('File ''%s'' not found.',filename),'File Not Found');
    uiwait(e)
    return
end

FileInfo.FileNameLong=filename;
[pathstr,name,ext]=fileparts(FileInfo.FileNameLong);
FileInfo.FileNameShort=sprintf('%s%s',name,ext);
FileInfo.FileNameNoExt=name;
FileInfo.FileFolder=pathstr;


fprintf('Converting ''%s''...',FileInfo.FileNameShort)

fid=fopen(FileInfo.FileNameLong);

if fid==-1
    e=errordlg(sprintf('Could not open ''%s''.',FileInfo.FileNameLong),'File Cannot Be Opened');
    uiwait(e)
    fprintf('\n\n')
    return
end

% Build a database with segment info
[FileInfo.SegInfo,FileInfo.NumOfSeg]=getSegInfo(fid);

% Build a database with channel info
[FileInfo.channelinfo, FileInfo.SegInfo]=getChannelInfo(fid,FileInfo.SegInfo,FileInfo.NumOfSeg);

% Add channel count to SegInfo
%SegInfo=addChanCount(SegInfo,channelinfo);
end

function [SegInfo,NumOfSeg]=getSegInfo(fid)
% Go through the whole file and build a database of the segment lead-in
% information:
%1) Count the total number of segments in the file.  (NumOfSeg)
%2) Get all of the "Lead In" Headers from all of the segements and store
%   that in the SegInfo variable:
%         SegInfo.SegStartPosn: Absolute Starting Position of Segment in file
%         SegInfo.MetaStartPosn: Absolute Starting Position of Meta Data in file
%         SegInfo.DataStartPosn: Absolute Starting Position of Raw Data in file
%         SegInfo.DataLength: Number of bytes of Data in segment
%         SegInfo.vernum: LV version number (4712 is v1.0, 4713 is v2.0)
%         SegInfo.NumChan: number of channels in this segement.  This is
%           only instatated in this function to 0.  The addChanCount function
%           updates this to the actual value later.
%
%         SegInfo.SegHasMetaData:  There is Meta Data in the Segement
%         SegInfo.SegHasRawData: There is Raw Data in the Segment
%         SegInfo.SegHasDaqMxRaw: There is DAQmxRaw Data in the Segment
%         SegInfo.SegInterleaved: 0: Contigous Data, 1: Interleaved Data
%         SegInfo.SegBigEndian:  0: Little, 1:Big (numeric, leadin, raw, and meta)
%         SegInfo.SegHasNewObjList: New object list in Segment
%
%3) While doing the above, also include error trapping for incompatibity

%Find the end of the file
fseek(fid,0,'eof');
eoff=ftell(fid);
frewind(fid);

segCnt=0;
CurrPosn=0;
LeadInByteCount=28;	%From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under
%the 'Lead In' description on page 2: Counted the bytes shown in the table.
while (ftell(fid) ~= eoff)
    
    Ttag=fread(fid,1,'uint8','l');
    Dtag=fread(fid,1,'uint8','l');
    Stag=fread(fid,1,'uint8','l');
    mtag=fread(fid,1,'uint8','l');
    
    if Ttag==84 && Dtag==68 && Stag==83 && mtag==109
        %Apparently, this sequence of numbers identifies the start of a new segment.
        
        segCnt=segCnt+1;
        
        %ToC Field
        ToC=fread(fid,1,'uint32','l');
        kTocBigEndian=bitget(ToC,7);
        if kTocBigEndian
            kTocEndian='b';
        else
            kTocEndian='l';
        end
        
        %TDMS format version number
        vernum=fread(fid,1,'uint32',kTocEndian);
        
        %From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under the 'Lead In'
        %description on page 2:
        %The next eight bytes (64-bit unsigned integer) describe the length of the remaining segment (overall length of the
        %segment minus length of the lead in). If further segments are appended to the file, this number can be used to
        %locate the starting point of the following segment. If an application encountered a severe problem while writing
        %to a TDMS file (crash, power outage), all bytes of this integer can be 0xFF. This can only happen to the last
        %segment in a file.
        nlen=fread(fid,1,'uint64',kTocEndian);
        if (nlen>2^63)
            break;
        else
            
            segLength=nlen;
        end
        TotalLength=segLength+LeadInByteCount;
        CurrPosn=CurrPosn+TotalLength;
        
        status=fseek(fid,CurrPosn,'bof');		%Move to the beginning position of the next segment
        if (status<0)
            warning('file glitch');
            break;
        end
    else  %TDSm should be the first charaters in a tdms file.  If not there, error out to stop hunting.
        fclose(fid);
        error('Unable to find TDSm tag. This may not be a tdms file, or you forgot to add the .tdms extension to the filename and are reading the wrong file');
        
    end
    
end

frewind(fid);

CurrPosn=0;
SegInfo.SegStartPosn=zeros(segCnt,1);
SegInfo.MetaStartPosn=zeros(segCnt,1);
SegInfo.DataStartPosn=zeros(segCnt,1);
SegInfo.vernum=zeros(segCnt,1);
SegInfo.DataLength=zeros(segCnt,1);
SegInfo.NumChan=zeros(segCnt,1);

SegInfo.SegHasMetaData=false(segCnt,1);
SegInfo.SegHasRawData=false(segCnt,1);
SegInfo.SegHasDaqMxRaw=false(segCnt,1);
SegInfo.SegInterleaved=false(segCnt,1);
SegInfo.SegBigEndian=false(segCnt,1);
SegInfo.SegHasNewObjList=false(segCnt,1);
segCnt=0;


while (ftell(fid) ~= eoff)
    
    Ttag=fread(fid,1,'uint8','l');
    Dtag=fread(fid,1,'uint8','l');
    Stag=fread(fid,1,'uint8','l');
    mtag=fread(fid,1,'uint8','l');
    
    if Ttag==84 && Dtag==68 && Stag==83 && mtag==109
        %Apparently, this sequence of numbers identifies the start of a new segment.
        %Leaving the above comment in, because it reflects that state of
        %the NI documenation on TDMS files when the contributers first started
        %developing this code. 
        
        segCnt=segCnt+1;
        
        if segCnt==1
            StartPosn=0;
        else
            StartPosn=CurrPosn;
        end
        
        %ToC Field
        ToC=fread(fid,1,'uint32','l');
        kTocBigEndian=bitget(ToC,7);
        kTocMetaData=bitget(ToC,2);
        kTocNewObjectList=bitget(ToC,3);
        kTocRawData=bitget(ToC,4);
        kTocDaqMxRawData=bitget(ToC,8);
        kTocInterleavedData=bitget(ToC,6);
        
        if kTocBigEndian
            kTocEndian='b';
        else
            kTocEndian='l';
        end
        
        %         if kTocInterleavedData
        %             error([sprintf(['\n Seqment %.0f of the above file has interleaved data which is not supported with this '...
        %                 'function. '],segCnt),'Interleaved Data Not Supported']);
        %             fclose(fid);
        %         end
        
%         if kTocBigEndian
%             error(sprintf(['\n Seqment %.0f of the above file uses the big-endian data format which is not supported '...
%                 'with this function. '],segCnt),'Big-Endian Data Format Not Supported');
%             fclose(fid);
%         end
        
        if kTocDaqMxRawData
            error(sprintf(['\n Seqment %.0f of the above file contains data in the DAQmxRaw NI datatype format which is not supported '...
                'with this function. See help documentation in convertTDMS.m for how to fix this. '],segCnt),'DAQmxRawData Format Not Supported');
            fclose(fid);
        end

        %TDMS format version number
        vernum=fread(fid,1,'uint32',kTocEndian);
        if ~ismember(vernum,[4712,4713])
            error(sprintf(['\n Seqment %.0f of the above file used LabView TDMS file format version %.0f which is not '...
                'supported with this function (%s.m).'],segCnt,vernum),...
                'TDMS File Format Not Supported');
            fclose(fid);
        end
        
        %From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under the 'Lead In'
        %description on page 2:
        %The next eight bytes (64-bit unsigned integer) describe the length of the remaining segment (overall length of the
        %segment minus length of the lead in). If further segments are appended to the file, this number can be used to
        %locate the starting point of the following segment. If an application encountered a severe problem while writing
        %to a TDMS file (crash, power outage), all bytes of this integer can be 0xFF. This can only happen to the last
        %segment in a file.
        segLength=fread(fid,1,'uint64',kTocEndian);
        metaLength=fread(fid,1,'uint64',kTocEndian);
        if (segLength>2^63)
            fseek(fid,0,'eof');
            flen=ftell(fid);
            segLength=flen-LeadInByteCount-TotalLength;
            TotalLength=segLength+LeadInByteCount;
        else
            TotalLength=segLength+LeadInByteCount;
            CurrPosn=CurrPosn+TotalLength;
            fseek(fid,CurrPosn,'bof');		%Move to the beginning position of the next segment
        end
        
        
        SegInfo.SegStartPosn(segCnt)=StartPosn;
        SegInfo.MetaStartPosn(segCnt)=StartPosn+LeadInByteCount;
        SegInfo.DataStartPosn(segCnt)=SegInfo.MetaStartPosn(segCnt)+metaLength;
        SegInfo.DataLength(segCnt)=segLength-metaLength;
        SegInfo.vernum(segCnt)=vernum;
        
        
        SegInfo.SegHasMetaData(segCnt)=kTocMetaData;
        SegInfo.SegHasRawData(segCnt)=kTocRawData;
        SegInfo.SegHasDaqMxRaw(segCnt)=kTocDaqMxRawData;
        SegInfo.SegInterleaved(segCnt)=kTocInterleavedData;
        SegInfo.SegBigEndian(segCnt)=kTocBigEndian;
        SegInfo.SegHasNewObjList(segCnt)=kTocNewObjectList;
        
        
    end
    
end
NumOfSeg=segCnt;
end

function [index,SegInfo]=getChannelInfo(fid,SegInfo,NumOfSeg)
%Loop through the segements and get all of the object information.

% name:  Short name such as Object3
% long_name: The path directory form of the object name
% rawdatacount: number of segments that have raw data for this object
% datastartindex:  Absolute position in file of the begining of all raw
%       data for the segment.  Add the rawdata offset to get to this object's
%       start point.
% arrayDim:  array dimension of raw data (for now should always be one as
%       NI does not support multi-dimension
% nValues:  number of values of raw data in segment
% byteSize: number of bytes for string/char data
% index:  segment numbers that contain raw data for this object
% rawdataoffset: offset from datastartindex for the begining of raw data
%       for this object
% multiplier: As part of LV's optimization, it will appenend raw data writes to the
%       TDMS file when meta data does not change, but forget to update the
%       nValues.  multiplier is the number of times the base pattern
%       repeats.
% skip: When multiple raw data writes are appended, this is the number of
%   bytes between the end of a channel in one block to the begining of that channel in
%   the next block.
% dataType:  The data type for this object. See LV2MatlabDataType function.
% datasize:  Number of bytes for each raw data entry.
% Property Structures:  Structure containg properties.


%Initialize variables for the file conversion
index=struct();
objOrderList={};


for segCnt=1:NumOfSeg
    
    %Go to the segment starting position of the segment
    fseek(fid,SegInfo.SegStartPosn(segCnt)+28,'bof');
    % +28 bytes: TDSm (4) + Toc (4) + segVer# (4) + segLength (8) + metaLength (8)
    
    %segVersionNum=SegInfo.vernum(segCnt);
    kTocMetaData=SegInfo.SegHasMetaData(segCnt);
    kTocNewObjectList=SegInfo.SegHasNewObjList(segCnt);
    kTocRawData=SegInfo.SegHasRawData(segCnt);
    kTocInterleavedData=SegInfo.SegInterleaved(segCnt);
    kTocBigEndian=SegInfo.SegBigEndian(segCnt);
    
    if kTocBigEndian
        kTocEndian='b';
    else
        kTocEndian='l';
    end
    
    %% Process Meta Data
    
    %If the object list from the last segment should be used....
    if (kTocNewObjectList==0)
        fnm=fieldnames(index);   %Get a list of the objects/channels to loop through
        for kk=1:length(fnm)
            ccnt=index.(fnm{kk}).rawdatacount;
            if (ccnt>0)   %If there is raw data info in the previous segement, copy it into the new segement
                if (index.(fnm{kk}).index(ccnt)==segCnt-1)
                    ccnt=ccnt+1;
                    index.(fnm{kk}).rawdatacount=ccnt;
                    index.(fnm{kk}).datastartindex(ccnt)=SegInfo.DataStartPosn(segCnt);
                    index.(fnm{kk}).arrayDim(ccnt)=index.(fnm{kk}).arrayDim(ccnt-1);
                    index.(fnm{kk}).nValues(ccnt)=index.(fnm{kk}).nValues(ccnt-1);
                    index.(fnm{kk}).byteSize(ccnt)=index.(fnm{kk}).byteSize(ccnt-1);
                    index.(fnm{kk}).index(ccnt)=segCnt;
                    index.(fnm{kk}).rawdataoffset(ccnt)=index.(fnm{kk}).rawdataoffset(ccnt-1);
                    SegInfo.NumChan(segCnt)=SegInfo.NumChan(segCnt)+1;
                end
            end
        end
    end
    
    
    %If there is Meta data in the segement
    if kTocMetaData
        numObjInSeg=fread(fid,1,'uint32',kTocEndian);
        if (kTocNewObjectList)
            objOrderList=cell(numObjInSeg,1);
        end
        for q=1:numObjInSeg
            
            obLength=fread(fid,1,'uint32',kTocEndian);						    %Get the length of the objects name
            ObjName=convertToText(fread(fid,obLength,'uint8','l'))';	%Get the objects name
            
            if strcmp(ObjName,'/')
                long_obname='Root';
            else
                long_obname=ObjName;
                
                %Delete any apostrophes.  If the first character is a slash (forward or backward), delete it too.
                long_obname(strfind(long_obname,''''))=[];
                if strcmpi(long_obname(1),'/') || strcmpi(long_obname(1),'\')
                    long_obname(1)=[];
                end
            end
            newob=0;
            %Create object's name.  Use a generic field name to avoid issues with strings that are too long and/or
            %characters that cannot be used in MATLAB variable names.  The actual channel name is retained for the final
            %output structure.
            if exist('ObjNameList','var')
                %Check to see if the object already exists
                NameIndex=find(strcmpi({ObjNameList.LongName},long_obname)==1,1,'first');
                if isempty(NameIndex)
                    newob=1;
                    %It does not exist, so create the generic name field name
                    ObjNameList(end+1).FieldName=sprintf('Object%.0f',numel(ObjNameList)+1);
                    ObjNameList(end).LongName=long_obname;
                    NameIndex=numel(ObjNameList);
                end
            else
                %No objects exist, so create the first one using a generic name field name.
                ObjNameList.FieldName='Object1';
                ObjNameList.LongName=long_obname;
                NameIndex=1;
                newob=1;
            end
            %Assign the generic field name
            obname=ObjNameList(NameIndex).FieldName;
            
            %Create the 'index' structure
            if (~isfield(index,obname))
                index.(obname).name=obname;
                index.(obname).long_name=long_obname;
                index.(obname).rawdatacount=0;
                index.(obname).datastartindex=zeros(NumOfSeg,1);
                index.(obname).arrayDim=zeros(NumOfSeg,1);
                index.(obname).nValues=zeros(NumOfSeg,1);
                index.(obname).byteSize=zeros(NumOfSeg,1);
                index.(obname).index=zeros(NumOfSeg,1);
                index.(obname).rawdataoffset=zeros(NumOfSeg,1);
                index.(obname).multiplier=ones(NumOfSeg,1);
                index.(obname).skip=zeros(NumOfSeg,1);
            end
            if (kTocNewObjectList)
                objOrderList{q}=obname;
            else
                if ~ismember(obname,objOrderList)
                    objOrderList{end+1}=obname;
                end
            end
            %Get the raw data Index
            rawdataindex=fread(fid,1,'uint32',kTocEndian);
            
            if rawdataindex==0
                if segCnt==0
                    e=errordlg(sprintf('Seqment %.0f within ''%s'' has ''rawdataindex'' value of 0 (%s.m).',segCnt,...
                        TDMSFileNameShort,mfilename),'Incorrect ''rawdataindex''');
                    uiwait(e)
                end
                if kTocRawData
                    if (kTocNewObjectList)
                        ccnt=index.(obname).rawdatacount+1;
                    else
                        ccnt=index.(obname).rawdatacount;
                    end
                    index.(obname).rawdatacount=ccnt;
                    index.(obname).datastartindex(ccnt)=SegInfo.DataStartPosn(segCnt);
                    index.(obname).arrayDim(ccnt)=index.(obname).arrayDim(ccnt-1);
                    index.(obname).nValues(ccnt)=index.(obname).nValues(ccnt-1);
                    index.(obname).byteSize(ccnt)=index.(obname).byteSize(ccnt-1);
                    index.(obname).index(ccnt)=segCnt;
                    SegInfo.NumChan(segCnt)=SegInfo.NumChan(segCnt)+1;
                end
            elseif rawdataindex+1==2^32
                %Objects raw data index matches previous index - no changes.  The root object will always have an
                %'FFFFFFFF' entry
                if strcmpi(index.(obname).long_name,'Root')
                    index.(obname).rawdataindex=0;
                else
                    %Need to account for the case where an object (besides the 'root') is added that has no data but reports
                    %using previous.
                    if newob
                        index.(obname).rawdataindex=0;
                    else
                        if kTocRawData
                            if (kTocNewObjectList)
                                ccnt=index.(obname).rawdatacount+1;
                            else
                                ccnt=index.(obname).rawdatacount;
                            end
                            index.(obname).rawdatacount=ccnt;
                            index.(obname).datastartindex(ccnt)=SegInfo.DataStartPosn(segCnt);
                            index.(obname).arrayDim(ccnt)=index.(obname).arrayDim(ccnt-1);
                            index.(obname).nValues(ccnt)=index.(obname).nValues(ccnt-1);
                            index.(obname).byteSize(ccnt)=index.(obname).byteSize(ccnt-1);
                            index.(obname).index(ccnt)=segCnt;
                            SegInfo.NumChan(segCnt)=SegInfo.NumChan(segCnt)+1;
                        end
                    end
                end
            else
                %Get new object information
                if (kTocNewObjectList)
                    ccnt=index.(obname).rawdatacount+1;
                else
                    ccnt=index.(obname).rawdatacount;
                    if (ccnt==0)
                        ccnt=1;
                    end
                end
                index.(obname).rawdatacount=ccnt;
                index.(obname).datastartindex(ccnt)=SegInfo.DataStartPosn(segCnt);
                %index(end).lenOfIndexInfo=fread(fid,1,'uint32');
                
                index.(obname).dataType=fread(fid,1,'uint32',kTocEndian);
                if (index.(obname).dataType~=32)
                    index.(obname).datasize=getDataSize(index.(obname).dataType);
                end
                index.(obname).arrayDim(ccnt)=fread(fid,1,'uint32',kTocEndian);
                index.(obname).nValues(ccnt)=fread(fid,1,'uint64',kTocEndian);
                index.(obname).index(ccnt)=segCnt;
                SegInfo.NumChan(segCnt)=SegInfo.NumChan(segCnt)+1;
                if index.(obname).dataType==32
                    %Datatype is a string
                    index.(obname).byteSize(ccnt)=fread(fid,1,'uint64',kTocEndian);
                else
                    index.(obname).byteSize(ccnt)=0;
                end
                
            end
            
            %Get the properties
            numProps=fread(fid,1,'uint32',kTocEndian);
            if numProps>0
                
                if isfield(index.(obname),'PropertyInfo')
                    PropertyInfo=index.(obname).PropertyInfo;
                else
                    clear PropertyInfo
                end
                for p=1:numProps
                    propNameLength=fread(fid,1,'uint32',kTocEndian);
                    switch 1
                        case 1
                            PropName=fread(fid,propNameLength,'*uint8','l')';
                            PropName=native2unicode(PropName,'UTF-8');
                        case 2
                            PropName=fread(fid,propNameLength,'uint8=>char','l')';
                        otherwise
                    end
                    propsDataType=fread(fid,1,'uint32',kTocEndian);
                    
                    %Create property's name.  Use a generic field name to avoid issues with strings that are too long and/or
                    %characters that cannot be used in MATLAB variable names.  The actual property name is retained for the
                    %final output structure.
                    if exist('PropertyInfo','var')
                        %Check to see if the property already exists for this object.  Need to get the existing 'PropertyInfo'
                        %structure for this object.  The 'PropertyInfo' structure is not necessarily the same for every
                        %object in the data file.
                        PropIndex=find(strcmpi({PropertyInfo.Name},PropName));
                        if isempty(PropIndex)
                            %Is does not exist, so create the generic name field name
                            propExists=false;
                            PropIndex=numel(PropertyInfo)+1;
                            propsName=sprintf('Property%.0f',PropIndex);
                            PropertyInfo(PropIndex).Name=PropName;
                            PropertyInfo(PropIndex).FieldName=propsName;
                        else
                            %Assign the generic field name
                            propExists=true;
                            propsName=PropertyInfo(PropIndex).FieldName;
                        end
                    else
                        %No properties exist for this object, so create the first one using a generic name field name.
                        propExists=false;
                        PropIndex=p;
                        propsName=sprintf('Property%.0f',PropIndex);
                        PropertyInfo(PropIndex).Name=PropName;
                        PropertyInfo(PropIndex).FieldName=propsName;
                    end
                    
                    dataExists=isfield(index.(obname),'data');
                    
                    %Get the number of samples already found and in the object
                    if dataExists
                        nsamps=index.(obname).nsamples+1;
                    else
                        nsamps=0;
                    end
                    
                    if propsDataType==32 %String data type
                        PropertyInfo(PropIndex).DataType='String';
                        propsValueLength=fread(fid,1,'uint32',kTocEndian);
                        propsValue=convertToText(fread(fid,propsValueLength,'uint8=>char',kTocEndian))';
                        if propExists
                            if isfield(index.(obname).(propsName),'cnt')
                                cnt=index.(obname).(propsName).cnt+1;
                            else
                                cnt=1;
                            end
                            index.(obname).(propsName).cnt=cnt;
                            index.(obname).(propsName).value{cnt}=propsValue;
                            index.(obname).(propsName).samples(cnt)=nsamps;
                        else
                            if strcmp(index.(obname).long_name,'Root')
                                %Header data
                                index.(obname).(propsName).name=index.(obname).long_name;
                                index.(obname).(propsName).value={propsValue};
                                index.(obname).(propsName).cnt=1;
                            else
                                index.(obname).(propsName).name=PropertyInfo(PropIndex).Name;
                                index.(obname).(propsName).datatype=PropertyInfo(PropIndex).DataType;
                                index.(obname).(propsName).cnt=1;
                                index.(obname).(propsName).value=cell(nsamps,1);		%Pre-allocation
                                index.(obname).(propsName).samples=zeros(nsamps,1);	%Pre-allocation
                                if iscell(propsValue)
                                    index.(obname).(propsName).value(1)=propsValue;
                                else
                                    index.(obname).(propsName).value(1)={propsValue};
                                end
                                index.(obname).(propsName).samples(1)=nsamps;
                            end
                        end
                    else %Numeric data type
                        if propsDataType==68 %Timestamp
                            PropertyInfo(PropIndex).DataType='Time';
                            %Timestamp data type
                            
                            if kTocBigEndian
                                tsec=fread(fid,1,'uint64','b')+fread(fid,1,'uint64','b')/2^64;	%time since Jan-1-1904 in seconds
                            else
                                tsec=fread(fid,1,'uint64','l')/2^64+fread(fid,1,'uint64','l');	%time since Jan-1-1904 in seconds
                            end
                            %tsec=fread(fid,1,'uint64',kTocEndian)/2^64+fread(fid,1,'uint64',kTocEndian);	%time since Jan-1-1904 in seconds
                            %R. Seltzer: Not sure why '5/24' (5 hours) is subtracted from the time value.  That's how it was
                            %coded in the original function I downloaded from MATLAB Central.  But I found it to be 1 hour too
                            %much.  So, I changed it to '4/24'.
                            %propsValue=tsec/86400+695422-5/24;	%/864000 convert to days; +695422 days from Jan-0-0000 to Jan-1-1904
                            propsValue=tsec/86400+695422-4/24;	%/864000 convert to days; +695422 days from Jan-0-0000 to Jan-1-1904
                        else  %Numeric
                            PropertyInfo(PropIndex).DataType='Numeric';
                            matType=LV2MatlabDataType(propsDataType);
                            if strcmp(matType,'Undefined')
                                e=errordlg(sprintf('No MATLAB data type defined for a ''Property Data Type'' value of ''%.0f''.',...
                                    propsDataType),'Undefined Property Data Type');
                                uiwait(e)
                                fclose(fid);
                                return
                            end
                            if strcmp(matType,'uint8=>char')
                                propsValue=convertToText(fread(fid,1,'uint8',kTocEndian));
                            else
                                propsValue=fread(fid,1,matType,kTocEndian);
                            end
                        end
                        if propExists
                            cnt=index.(obname).(propsName).cnt+1;
                            index.(obname).(propsName).cnt=cnt;
                            index.(obname).(propsName).value(cnt)=propsValue;
                            index.(obname).(propsName).samples(cnt)=nsamps;
                        else
                            index.(obname).(propsName).name=PropertyInfo(PropIndex).Name;
                            index.(obname).(propsName).datatype=PropertyInfo(PropIndex).DataType;
                            index.(obname).(propsName).cnt=1;
                            index.(obname).(propsName).value=NaN(nsamps,1);				%Pre-allocation
                            index.(obname).(propsName).samples=zeros(nsamps,1);		%Pre-allocation
                            index.(obname).(propsName).value(1)=propsValue;
                            index.(obname).(propsName).samples(1)=nsamps;
                        end
                    end
                    
                end	%'end' for the 'Property' loop
                index.(obname).PropertyInfo=PropertyInfo;
                
            end
            
        end	%'end' for the 'Objects' loop
    end
    
 


    
    
    %Address Decimation and Interleaving
    if (kTocRawData)
        
        singleSegDataSize=0;
        rawDataBytes=0;
        chanBytes=0;
        rawDataOffset=0;
        
        for kk=1:numel(objOrderList)
            obname=objOrderList{kk};
            ccnt=hasRawDataInSeg(segCnt,index.(obname));
            if ccnt>0   %If segement has raw data
                index.(obname).rawdataoffset(ccnt)=rawDataOffset;
                if index.(obname).dataType==32 %Datatype is a string
                    rawDataBytes=index.(obname).byteSize(ccnt);
                else
                    rawDataBytes=index.(obname).nValues(ccnt)*index.(obname).datasize;
                    if kTocInterleavedData
                        chanBytes=index.(obname).datasize;
                    else
                        chanBytes=rawDataBytes;
                    end
                    
                end
                rawDataOffset=rawDataOffset+chanBytes;
                singleSegDataSize=singleSegDataSize+rawDataBytes;
            end
        end
        
        
        
        
        %Calculate the offset for each segment.  The offset is the amount
        %of bytes for one non appened (non optimized) segement
%         for kk=1:numel(objOrderList)
%             obname=objOrderList{kk};
%             if hasRawDataInSeg(segCnt,index.(obname))   %If segement has raw data
%                 index.(obname).rawdataoffset(ccnt)=rawdataoffset;      %This will set the offset correctly for dec data.
%                 
%                 %Update the singleSegDataSize value for the next object
%                 if index.(obname).dataType==32 %Datatype is a string
%                     singleSegDataSize=singleSegDataSize+index.(obname).byteSize(ccnt);
%                 else
%                     singleSegDataSize=singleSegDataSize+index.(obname).nValues(ccnt)*index.(obname).datasize;
%                 end
%                 
%                 if kTocInterleavedData
%                     rawdataoffset=
%                 else
%                     rawdataoffset=singleSegDataSize;
%                 end
%             end
%         end
%         

                    
                    
        

        %As part of LV's optimization, it will append back to back
        %segements into one segement (when nothing changes in meta data).
        if (singleSegDataSize~=SegInfo.DataLength(segCnt))         %Multiple appended raw segement (offset did not grow to be greater than the DataLength)
            numAppSegs=floor(SegInfo.DataLength(segCnt)/singleSegDataSize);  %Number of appened (optimized segements)
            for kk=1:numel(objOrderList)   %Loop through all the objects
                obname=objOrderList{kk};
                ccnt=hasRawDataInSeg(segCnt,index.(obname));
                if ccnt>0   %If segement has raw data
                    if kTocInterleavedData
                        if index.(obname).dataType==32 %Datatype is a string
                            error('Interleaved string channels are not supported.')
                        end
                        index.(obname).multiplier(ccnt)=numAppSegs*index.(obname).nValues(ccnt);
                        index.(obname).skip(ccnt)=singleSegDataSize/index.(obname).nValues(ccnt)-index.(obname).datasize;
                        index.(obname).nValues(ccnt)=1;
                    else  %Decimated Data
                        index.(obname).multiplier(ccnt)=numAppSegs;
                        if index.(obname).dataType==32 %Datatype is a string
                            index.(obname).skip(ccnt)=singleSegDataSize-index.(obname).byteSize(ccnt);
                        else
                            index.(obname).skip(ccnt)=singleSegDataSize-index.(obname).nValues(ccnt)*index.(obname).datasize;
                        end
                    end
                end
                
            end
        else   %If single segement
            if kTocInterleavedData
                for kk=1:numel(objOrderList)   %Loop through all the objects
                    obname=objOrderList{kk};
                    ccnt=hasRawDataInSeg(segCnt,index.(obname));
                    if ccnt>0  %If segement has raw data
                        if (index.(obname).index(ccnt)==segCnt)   %If the object has rawdata in the current segment
                            if index.(obname).dataType==32 %Datatype is a string
                               error('Interleaved string channels are not supported.')  
                            end
                            index.(obname).multiplier(ccnt)=index.(obname).nValues(ccnt);
                            index.(obname).skip(ccnt)=singleSegDataSize/index.(obname).nValues(ccnt)-index.(obname).datasize;
                            index.(obname).nValues(ccnt)=1;
                        end
                    end
                end
            end
        end
        

        
%         if (offset~=SegInfo.DataLength(segCnt))         %If the offset grew to be greater than the DataLength (from Meta Data)
%             multiplier=floor(SegInfo.DataLength(segCnt)/offset);
%             for kk=1:numel(objOrderList)   %Loop through the objects 
%                 obname=objOrderList{kk};
%                 ccnt=index.(obname).rawdatacount;
%                 if ccnt>0
%                     index.(obname).multiplier(segCnt)=multiplier;
%                     if index.(obname).dataType==32 %Datatype is a string
%                         index.(obname).skip(ccnt)=offset-index.(obname).byteSize(ccnt);
%                     else
%                         index.(obname).skip(ccnt)=offset-index.(obname).nValues(ccnt)*index.(obname).datasize;
%                     end
%                 end
%             end
%             
%         end
        
        aa=1;
%         %Now adjust multiplier and skip if the data is interleaved
%         if kTocInterleavedData
%             if muliplier>0  %Muliple raw data segements appened
%                 
%             else   %Single raw segement
%         
%             end
%         end
        
    end
    
end
%clean up the index if it has to much data
fnm=fieldnames(index);
for kk=1:numel(fnm)
    ccnt=index.(fnm{kk}).rawdatacount+1;
    
    index.(fnm{kk}).datastartindex(ccnt:end)=[];
    index.(fnm{kk}).arrayDim(ccnt:end)=[];
    index.(fnm{kk}).nValues(ccnt:end)=[];
    index.(fnm{kk}).byteSize(ccnt:end)=[];
    index.(fnm{kk}).index(ccnt:end)=[];
    index.(fnm{kk}).rawdataoffset(ccnt:end)=[];
    index.(fnm{kk}).multiplier(ccnt:end)=[];
    index.(fnm{kk}).skip(ccnt:end)=[];
    
end
end

