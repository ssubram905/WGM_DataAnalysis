function fileprops = setfileProperties(filename)
% setfileProperties - set the fileinfo property depending on the
%                     the input file type
p = inputParser;
p.FunctionName = 'setfileProperties';
addRequired(p,'filename',@(x) ischar(x));
parse(p,filename);

filename = p.Results.filename;
[filepath,~,ext] = fileparts(filename);
if strcmpi(ext,'.txt')
    FileInfo = importdata(filename);
elseif strcmpi(ext,'.tdms')
    FileInfo = getInputFile(0,filename);
    if isfile(fullfile(filepath,'scalingFactorLockin.mat'))
        sfilepath = filepath;
        sfilename = 'scalingFactorLockin.mat';
    else
    [sfilename,sfilepath] = uigetfile('*.mat','Scaling Factor File',...
        FileInfo.FileFolder);
    end
    if sfilename
        scale = load(fullfile(sfilepath,sfilename));
    end
    FileInfo.scaleFilepath = fullfile(sfilepath,sfilename);
    FileInfo.scale = scale;
else
    errordlg('File format not recognized. Please select the correct input file',...
        'File error');
end
fileprops.ext = ext;
fileprops.FileInfo = FileInfo;

end