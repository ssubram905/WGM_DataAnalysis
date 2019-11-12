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
