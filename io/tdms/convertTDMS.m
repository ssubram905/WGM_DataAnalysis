function [ConvertedData,ConvertVer,ChanNames,GroupNames,ci]=convertTDMS(FileInfo,startTime,plotTime,scanrate )
%Function to load LabView TDMS data file(s) into variables in the MATLAB workspace.
%An *.MAT file can also be created.  If called with one input, the user selects
%a data file.
%
%   TDMS format is based on information provided by National Instruments at:
%   http://zone.ni.com/devzone/cda/tut/p/id/5696
%
% [ConvertedData,ConvertVer,ChanNames]=convertTDMS(SaveConvertedFile,filename)
%
%       Inputs:
%               SaveConvertedFile (required) - Logical flag (true/false) that
%                 determines whether a MAT file is created.  The MAT file's name
%                 is the same as 'filename' except that the 'TDMS' file extension is
%                 replaced with 'MAT'.  The MAT file is saved in the same folder
%                 and will overwrite an existing file without warning.  The
%                 MAT file contains all the output variables.
%
%               filename (optional) - Filename (fully defined) to be converted.
%                 If not supplied, the user is provided a 'File Open' dialog box
%                 to navigate to a file.  Can be a cell array of files for bulk
%                 conversion.
%
%       Outputs:
%               ConvertedData (required) - Structure of all of the data objects.
%               ConvertVer (optional) - Version number of this function.
%               ChanNames (optional) - Cell array of channel names
%               GroupNames (optional) - Cell array of group names
%               ci (optional) - Structure of the channel index (an index to
%                   where all of the information for a channel resides in a
%                   file.
%
%
%'ConvertedData' is a structure with 'FileName', 'FileFolder', 'SegTDMSVerNum',
%'NumOfSegments' and 'Data' fields'. The 'Data' field is a structure.
%
%'ConvertedData.SegTDMSVerNum' is a vector of the TDMS version number for each
%segment.
%
%'ConvertedData.Data' is a structure with 'Root' and 'MeasuredData' fields.
%
%'ConvertedData.Data.Root' is a structure with 'Name' and 'Property' fields.
%The 'Property' field is also a structure; it contains all the specified properties
%(1 entry for each 'Property) for the 'Root' group. For each 'Property' there are
%'Name' and 'Value' fields. To display a list of all the property names, input
%'{ConvertedData.Data.Root.Property.Name}'' in the Command Window.
%
%'ConvertedData.Data.MeasuredData' is a structure containing all the channel/group
%information. For each index (for example, 'ConvertedData.Data.MeasuredData(1)'),
%there are 'Name', 'Data' and 'Property' fields.  The list of channel names can
%be displayed by typing 'ChanNames' in the Command Window.  Similarly, the list
%of group names can be displayed by typing 'GroupNames' in the Command Window.
%The 'Property' field is also a structure; it contains all the specified properties
%for that index (1 entry in the structure for each 'Property'). Any LabView waveform
%attributes ('wf_start_time', 'wf_start_offset', 'wf_increment' and 'wf_samples') that
%may exist are also included in the properties. For each 'Property' there are 'Name'
%and 'Value' fields.  To display a list of all the property names, input
%'{ConvertedData.Data.MeasuredData(#).Property.Name}'' in the Command Window
%where '#' is the index of interest.
%
%If you recieve an error that DAQmxRaw data cannot be converted, this is due
%to the details on parsing this data type not being published by NI.  the
%work around is to use a VI that reads in the data file and then writes it
%to a new file.  See: https://decibel.ni.com/content/docs/DOC-32817
%
%  See Also: simpleconvertTDMS

%-------------------------------------------------------------------------
%Brad Humphreys - v1.0 2008-04-23
%ZIN Technologies
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Brad Humphreys - v1.1 2008-07-03
%ZIN Technologies
%-Added abilty for timestamp to be a raw data type, not just meta data.
%-Addressed an issue with having a default nsmaples entry for new objects.
%-Added Error trap if file name not found.
%-Corrected significant problem where it was assumed that once an object
%    existsed, it would in in every subsequent segement.  This is not true.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Grant Lohsen - v1.2 2009-11-15
%Georgia Tech Research Institute
%-Converts TDMS v2 files
%Folks, it's not pretty but I don't have time to make it pretty. Enjoy.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Jeff Sitterle - v1.3 2010-01-10
%Georgia Tech Research Institute
%Modified to return all information stored in the TDMS file to inlcude
%name, start time, start time offset, samples per read, total samples, unit
%description, and unit string.  Also provides event time and event
%description in text form
%Vast speed improvement as save was the previous longest task
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Grant Lohsen - v1.4 2009-04-15
%Georgia Tech Research Institute
%Reads file header info and stores in the Root Structure.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.5 2010-07-14
%BorgWarner Morse TEC
%-Tested in MATLAB 2007b and 2010a.
%-APPEARS to now be compatible with TDMS version 1.1 (a.k.a 4712) files;
%	although, this has not been extensively tested.  For some unknown
%	reason, the version 1.2 (4713) files process noticeably faster. I think
%	that it may be related to the 'TDSm' tag.
%-"Time Stamp" data type was not tested.
%-"Waveform" fields was not tested.
%-Fixed an error in the 'LV2MatlabDataType' function where LabView data type
%	'tdsTypeSingleFloat' was defined as MATLAB data type 'float64' .  Changed
%	to 'float32'.
%-Added error trapping.
%-Added feature to count the number of segments for pre-allocation as
%	opposed to estimating the number of segments.
%-Added option to save the data in a MAT file.
%-Fixed "invalid field name" error caused by excessive string lengths.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.6 2010-09-01
%BorgWarner Morse TEC
%-Tested in MATLAB 2010a.
%-Fixed the "Coversion to cell from char is not possible" error found
%  by Francisco Botero in version 1.5.
%-Added capability to process both fragmented or defragmented data.
%-Fixed the "field" error found by Lawrence.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Christian Buxel - V1.7 2010-09-17
%RWTH Aachen
%-Tested in Matlab2007b.
%-Added support for german umlauts (�,�,�,�,�,�,�) in 'propsName'
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Andr� R�egg - V1.7 2010-09-29
%Supercomputing Systems AG
%-Tested in MATLAB 2006a & 2010b
%-Make sure that data can be loaded correctly independently of character
% encoding set in matlab.
%-Fixed error if object consists of several segments with identical segment
% information (if rawdataindex==0, not all segments were loaded)
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.7 2010-09-30
%BorgWarner Morse TEC
%-Tested in MATLAB 2010b.
%-Added 'error trapping' to the 'fixcharformatlab' function for group and
% channel names that contain characters that are not 'A' through 'Z',
% 'a' through 'z', 0 through 9 or underscore. The characters are replaced
% with an underscore and a message is written to the Command Window
% explaining to the user what has happened and how to fix it. Only tested
% with a very limited number of "special" characters.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.8 2010-10-12
%BorgWarner Morse TEC
%-As a result of an error found by Peter Sulcs when loading data with very
% long channel names, I have re-written the sections of the function that
% creates the channel and property names that are used within the body of
% the function to make them robust against long strings and strings
% containing non-UTF8 characters.  The original channel and property
% names (no truncation or character replacement) are now retained and
% included in the output structure.  In order to implement this improvement,
% I added a 'Property' field as a structure to the 'ConvertedData' output
% structure.
%-Added a more detailed 'help' description ('doc convertTDMS') of the
% returned structure.
%-List of channel names added as an output parameter of the function.
%-Corrected an error in the time stamp converion. It was off by exactly
% 1 hour.
%-Tested in MATLAB 2010b with a limited number of diverse TDMS files.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.8 2010-10-19
%BorgWarner Morse TEC
%-Fixed an error found by Terenzio Girotto with the 'save' routine.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.8 2010-10-25
%BorgWarner Morse TEC
%-Fixed an error with channels that contain no data.  Previously, if a
% channel contained no data, then it was not passed to the output structure
% even if it did contain properties.
%-Added 'GroupNames' as an optional output variable.
%-Fixed an error with capturing the properties of the Root object
%-------------------------------------------------------------------------


%-------------------------------------------------------------------------
%Philip Top - v1.9 2010-11-09
%John Breneman
%-restructured code as function calls
%-seperated metadata reads from data reads
%-preallocated space for SegInfo with two pass file read
%-preallocated index information and defined segdataoffset for each segment
%-preallocate space for data for speedup in case of fragmented files
%-used matlab input parser instead of nargin switch
%-vectorized timestamp reads for substantial speedup
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Robert Seltzer - v1.9 2010-11-10
%BorgWarner Morse TEC
%-Fixed an error error in the 'offset' calculation for strings
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Philip Top - v1.95 2011-5-10
%Fix Bug with out of order file segments
%Fix some issues with string array reads for newer version files,
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Brad Humphreys - v1.96 2013-10-9
%Fixed problem with error catch messages themselves (interleaved, version,
%big endian) using the TDMSFileName variable which was not available
%(passed into) the getSegInfo function.  Added ability to work with
%interleaved and big endian files.
%So function now covers:
%       -v1.0-v2.0
%       -Interleaved and Decimated Data Formats
%       -Big and Little Endian storage
% Does not work with DAQmxRawData
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Brad Humphreys - v1.97 2013-11-13
%Added information to help documentation on how to deal with DAQmxRaw Data.
%-------------------------------------------------------------------------


%-------------------------------------------------------------------------
%Brad Humphreys - v1.98 2014-5-27
%Per G. Lohsen's suggestion, added check to verify that first caharters are
% TDMs.  If not, errors out and lets user know that the selected file is
% not a TDMS file.
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%Sebastian Schwarzendahl (alias Haench) - v1.99 2014-10-23
% Added support for complex data types
% CSG - tdsTypeComplexSingleFloat=0x08000c
% CDB - tdsTypeComplexDoubleFloat=0x10000d)
% This feature was added in LV2013 (I believ) and produced an error in
% the previous version of this code.
%-------------------------------------------------------------------------
%Initialize outputs

ConvertVer='1.98';    %Version number of this conversion function

fid=fopen(FileInfo.FileNameLong);

if fid==-1
    e=errordlg(sprintf('Could not open ''%s''.',FileInfo.FileNameLong),'File Cannot Be Opened');
    uiwait(e)
    fprintf('\n\n')
    return
end

%Since the data is large get a subset of the data depending on the free
%memory
samplestoread = round(scanrate*plotTime);
startIndex = round(startTime*scanrate);

% Get the raw data
ob = readTDMS(fid,FileInfo.channelinfo,FileInfo.SegInfo, samplestoread, startIndex);  
%Returns the objects which have data.  See postProcess function (appends to all of the objects)
fclose(fid);

%Assign the outputs
ConvertedData.FileName=FileInfo.FileNameShort;
ConvertedData.FileFolder=FileInfo.FileFolder;

ConvertedData.SegTDMSVerNum=FileInfo.SegInfo.vernum;
ConvertedData.NumOfSegments=FileInfo.NumOfSeg;
[ConvertedData.Data,CurrGroupNames]=postProcess(ob,FileInfo.channelinfo);

GroupNames={CurrGroupNames};

TempChanNames={ConvertedData.Data.MeasuredData.Name};
TempChanNames(strcmpi(TempChanNames,'Root'))=[];
ChanNames={sort(setdiff(TempChanNames',CurrGroupNames))};
if FileInfo.SaveConvertedFile
    MATFileNameShort=sprintf('%s.mat',FileNameNoExt);
    MATFileNameLong=fullfile(FileFolder,MATFileNameShort);
    try
        save(MATFileNameLong,'ConvertedData','ConvertVer','ChanNames')
        fprintf('\n\nConversion complete (saved in ''%s'').\n\n',MATFileNameShort)
    catch exception
        fprintf('\n\nConversion complete (could not save ''%s'').\n\t%s: %s\n\n',MATFileNameShort,exception.identifier,...
            exception.message)
    end
else
    fprintf('\n\nConversion complete.\n\n')
end

ci=FileInfo.channelinfo;
end













