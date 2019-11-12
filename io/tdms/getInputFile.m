function [FileInfo ] = getInputFile(varargin)


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
