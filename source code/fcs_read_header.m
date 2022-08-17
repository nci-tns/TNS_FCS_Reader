function [fcshdr, mnemonic_separator] = fcs_read_header(filename)
% [fcsdat, fcshdr, fcsdatscaled, fcsdat_comp] = fca_readfcs(filename);
%
% Read FCS 2.0, 3.0 and 3.1 type flow cytometry data file and put the list mode
% parameters to the fcsdat array with the size of [NumOfPar TotalEvents].
% Some important header data are stored in the fcshdr structure:
% TotalEvents, NumOfPar, starttime, stoptime and specific info for parameters
% as name, range, bitdepth, logscale(yes-no) and number of decades.

% calculate compensated events needs fixing

fcshdr = [];

% if noarg was supplied
if nargin == 0 % no inputted arguments
    [FileName, FilePath] = uigetfile('*.*','Select FCS file'); % select any file type, does not have to be fcs2.0 file
    filename = [FilePath,FileName];
    if FileName == 0 % if no file selected, return null arrays
        fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
        return;
    end
else % Removes the NULL ascii character if it exists. This makes strange things!
    filename_asciicode = int16(filename);
    filename(find(filename_asciicode==0)) = [];
    filecheck = dir(filename);
    if size(filecheck,1) == 0 || size(filecheck,1) >1 % if no file exists or multiple files share name--could probably ask to choose
%         msgbox([filename,': The FCS file or the source directory does not exist!'], ...
%             'FCS reading info','warn');
        fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
        return;
    end
end

% if filename arg. only contain PATH, set the default dir to this
% before issuing the uigetfile command. This is an option for the "fca"
% tool
[FilePath, FileNameMain, fext] = fileparts(filename);
FilePath = [FilePath filesep];
FileName = [FileNameMain, fext];
if isempty(FileNameMain)
    currend_dir = cd;
    cd(FilePath);
    [FileName, FilePath] = uigetfile('*.*','Select FCS file');
    filename = [FilePath,FileName];
    if FileName == 0
        fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
        return;
    end
    cd(currend_dir); % changes back to original current folder
end

% Reading the File
fid = fopen(filename,'r','b');
fcsheader_1stline = fread(fid,64,'char');
fcsheader_type = char(fcsheader_1stline(1:6)'); % first six characters should always be FCS2.0, FCS3.0, ...

%% Reading the Header
if contains(fcsheader_type,'FCS1.0')
%     msgbox('FCS 1.0 file type is not supported!','FCS reading info','warn');
    fcsdat = []; fcshdr = []; fcsdatscaled= []; fcsdatcomp= [];
    fclose(fid);
    return;
elseif contains(fcsheader_type,'FCS2.0') || contains(fcsheader_type,'FCS3.0')  || contains(fcsheader_type,'FCS3.1') % FCS2.0 or FCS3.0 or FCS3.1 types
    fcshdr.fcstype = fcsheader_type;
    FcsHeaderStartPos   = str2double(char(fcsheader_1stline(11:18)'));
    FcsHeaderStopPos    = str2double(char(fcsheader_1stline(19:26)'));
    FcsDataStartPos     = str2double(char(fcsheader_1stline(27:34)'));
    fseek(fid,0,'bof');
    fcsheader_total = fread(fid,FcsHeaderStopPos+1,'char'); %read the total header
    fseek(fid,FcsHeaderStartPos,'bof');
    fcsheader_main = fread(fid,FcsHeaderStopPos-FcsHeaderStartPos+1,'char'); %read the main header
    char_fcsheader = char(fcsheader_main)'; % converts fcsheader_main into characters
    warning off MATLAB:nonIntegerTruncatedInConversionToChar; % turns off warning
    fcshdr.Filename = FileName;
    fcshdr.Filepath = FilePath;
    
    % Mnemonic Separator--The first character of the primary TEXT segment contains the delimiter (FCS standard)
    mnemonic_separator = char(fcsheader_main(1));
    double_mnem_sep = fcsheader_main(1);
    
    % if the file size larger than ~100Mbyte the previously defined
    % FcsDataStartPos = 0. In that case the $BEGINDATA parameter stores the correct value
    if ~FcsDataStartPos % if first line does not store data start position
        FcsDataStartPos = str2double(get_mnemonic_value('$BEGINDATA',fcsheader_main, mnemonic_separator));
    end
    if mnemonic_separator == '@' % WinMDI
        msgbox([FileName,': The file can not be read (Unsupported FCS type: WinMDI histogram file)'],'FCS reading info','warn');
        fcsdat = []; fcshdr = [];fcsdatscaled= []; fcsdatcomp= [];
        fclose(fid);
        return;
    end
    
    % Standardized FCSHDR (as from FCS1.0 File Standards)
    % Start reading through the header using mnemonic separators of specific mnemonic names to read off their values
    fcshdr.FULLFCSHEADER = char_fcsheader;
    fcshdr.CYT      = get_mnemonic_value('$CYT',fcsheader_main, mnemonic_separator);
    fcshdr.TOT      = str2double(get_mnemonic_value('$TOT',fcsheader_main, mnemonic_separator));
    fcshdr.PAR      = str2double(get_mnemonic_value('$PAR',fcsheader_main, mnemonic_separator));
    fcshdr.BYTEORD  = get_mnemonic_value('$BYTEORD',fcsheader_main, mnemonic_separator);
    fcshdr.DATATYPE = get_mnemonic_value('$DATATYPE',fcsheader_main, mnemonic_separator);
    if fcshdr.TOT == 0 % if no total events, then no data
        fcsdat = 0;
        fcsdatscaled = 0;
        return
    end
    
    % Determine MachineFormat
    if contains(fcshdr.BYTEORD, '1,2,3,4')
        machineformat = 'ieee-le';
    elseif contains(fcshdr.BYTEORD, '4,3,2,1')
        machineformat = 'ieee-be';
    end
    
    % Additional FCS Header
    % Different Cytometers write different mnemonic names so they must be inputted manually for each cytometer
    if contains(char_fcsheader, 'Aria', 'IgnoreCase', true) % for all information from MoFlo Astrios cytometer
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = FACSAria(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Astrios', 'IgnoreCase', true) % for all information from MoFlo Astrios cytometer
        [fcshdr, fcshdr.Parameters, fcshdr.Misc] = Astrios(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Attune', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = AttuneNxT(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Aurora', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = Aurora(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Canto', 'IgnoreCase', true) || contains(char_fcsheader, 'LSR', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = Canto(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'CytoFLEX', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Channels] = CytoFLEX(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Image Stream', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = ImageStream(fcsheader_main, fcshdr, mnemonic_separator);    
    elseif contains(char_fcsheader, 'Fortessa', 'IgnoreCase', true) || contains(char_fcsheader, 'Symphony', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = Fortessa(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Influx', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Lasers] = Influx(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(fcshdr.CYT, 'Micro', 'IgnoreCase', true) || contains(char_fcsheader, 'Apogee', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc] = Apogee(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'MoFlo', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc] = MoFloXDP(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'NanoFCM', 'IgnoreCase', true) || contains(fcshdr.CYT, 'Nano', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc, fcshdr.Channels] = NanoFCM(fcsheader_main, fcshdr, mnemonic_separator);
    elseif contains(char_fcsheader, 'Quanteon', 'IgnoreCase', true)
        [fcshdr, fcshdr.Parameters, fcshdr.Misc] = Quanteon(fcsheader_main, fcshdr, mnemonic_separator);
    else
%         msgbox('Cannot determine cytometer from FCS file or cytometer is unsupported.', 'Error', 'warn');
    end
    if isempty(fcshdr.CYT)
        fcshdr.CYT = 'Unknown';
    end
    fcshdr.Misc.MnemonicSep = double_mnem_sep;
    %fcshdr.Misc.Char_fcsheader = char_fcsheader;
    
else % if first line does not start with FCS2.0, FCS3.0, ...
    msgbox([FileName,': The file can not be read (Unsupported FCS type)'],'FCS reading info','warn');
    fcsdat = []; fcshdr = []; fcsdatscaled = []; fcsdatcomp = [];
    fclose(fid);
    return;
end

end

%% calculate the compensated events
% if nargout > 3 && ~isempty(fcshdr.CompLabels)
%     compcols = zeros(1, nc);
%     colLabels = {fcshdr.Parameters.Name};
%     for i = 1:nc
%         compcols(i) = find(strcmp(fcshdr.CompLabels{i}, colLabels));
%     end
%     fcsdatcomp = fcsdatscaled;
%     fcsdatcomp(:,compcols) = fcsdatcomp(:,compcols)/fcshdr.CompMat;
% else
%     fcsdatcomp=[];
% end

function mneval = get_mnemonic_value(mnemonic_name, fcsheader, mnemonic_separator)
% Adds mnemonic separator to end as mnemonic name can appear more than once
% in fcsheader
mnemonic_separator = double(mnemonic_separator);
mnemonic_name = double(mnemonic_name); % convert to decimals
mnemonic_name = [mnemonic_name mnemonic_separator]; % add mnemonic separator to end which specifies which name
mnemonic_name = char(mnemonic_name); % convert back to characters to search through fcsheader
mnemonic_startpos = strfind(char(fcsheader'),mnemonic_name); % finds the mnemonic name in the fcsheader
if isempty(mnemonic_startpos) % if the mnemonic name is not found, return the null array
    %mneval = [];
    mneval = ''; % return the empty string instead of empty array
    return;
else
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_separators = strfind(char(fcsheader(mnemonic_stoppos:end)'), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    next_separator = next_separators(1) + mnemonic_stoppos; % the next mnemonic separator
    mneval = char(fcsheader(mnemonic_stoppos : next_separator - 2)');
end