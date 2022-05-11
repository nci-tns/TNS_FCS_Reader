function [fcshdr, Par, Misc, Channel] = NanoFCM(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays
% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
% Only cytometer without some sort of spillover data
fcshdr.CREATOR = get_mnemonic_value('$CREATOR', fcsheader_main, mnemonic_separator);
fcshdr.SYS     = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
fcshdr.OP      = get_mnemonic_value('$OP', fcsheader_main, mnemonic_separator);
fcshdr.DATE    = get_mnemonic_value('$DATE', fcsheader_main, mnemonic_separator);
fcshdr.ETIM    = get_mnemonic_value('$ETIM', fcsheader_main, mnemonic_separator);
fcshdr.MODE    = get_mnemonic_value('$MODE', fcsheader_main, mnemonic_separator);
fcshdr.CYTSN   = get_mnemonic_value('$CYTSN', fcsheader_main, mnemonic_separator);
fcshdr.FIL     = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);
fcshdr.SPILLOVER = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);

% Parameters
NumOfPar = str2double(get_mnemonic_value('$PAR', fcsheader_main, mnemonic_separator));
Par = struct('Name', cell(1, NumOfPar), 'Range', cell(1, NumOfPar), 'Bit', ...
    cell(1, NumOfPar), 'Voltage', cell(1, NumOfPar), 'Gain', cell(1, NumOfPar), ...
    'Log', cell(1, NumOfPar), 'Decade', cell(1, NumOfPar), 'Logzero', ...
    cell(1, NumOfPar), 'BS', cell(1, NumOfPar), 'MS', cell(1, NumOfPar), 'Display_', ...
    cell(1, NumOfPar), 'Amp', cell(1, NumOfPar));
for i=1:NumOfPar
    Par(i).Name     = get_mnemonic_value(['$P',num2str(i),'N'], fcsheader_main, mnemonic_separator);
    Par(i).Range    = get_mnemonic_value(['$P',num2str(i),'R'], fcsheader_main, mnemonic_separator);
    Par(i).Bit      = get_mnemonic_value(['$P',num2str(i),'B'], fcsheader_main, mnemonic_separator);
    Par(i).Voltage  = get_mnemonic_value(['$P',num2str(i),'V'], fcsheader_main, mnemonic_separator);
    Par(i).Gain     = get_mnemonic_value(['$P',num2str(i),'G'], fcsheader_main, mnemonic_separator);
    Par(i).BS       = get_mnemonic_value(['P',num2str(i),'BS'], fcsheader_main, mnemonic_separator);
    Par(i).MS       = get_mnemonic_value(['P',num2str(i),'MS'], fcsheader_main, mnemonic_separator);
    Par(i).Display_ = get_mnemonic_value(['P',num2str(i),'DISPLAY'], fcsheader_main, mnemonic_separator);
    Par(i).Amp      = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    
    %LIN/LOG
    % In FCS 3.1, all floating data is treated as LIN rather than LOG for $PiE--so all $PiE are stored as 0,0,
    % so use PiDISPLAY and an assumed decade of 5--not sure what is desired here
    islogpar = get_mnemonic_value(['P',num2str(i),'DISPLAY'], fcsheader_main, mnemonic_separator);
    if strcmp(islogpar, 'LOG')
        par_exponent_str = '5,1';
    else % islogpar = LIN case
        par_exponent_str = '0,0';
    end
    par_exponent= str2num(par_exponent_str); % converts string to matrix to store decade and log values
    Par(i).Decade = par_exponent(1);
    if Par(i).Decade == 0
        Par(i).Log = 0;
        Par(i).Logzero = 0;
    else
        Par(i).Log = 1;
        Par(i).Logzero = par_exponent(2);
    end
end

% Miscellaneous
Misc.LASER         = get_mnemonic_value('LASER', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA     = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA       = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS   = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT     = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT       = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
if isempty(get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator)) % fixs issue with nanoFCM having a space after $NEXTDATA
    Misc.NEXTDATA  = get_mnemonic_value('$NEXTDATA ', fcsheader_main, mnemonic_separator);
else
Misc.NEXTDATA      = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);
end

% Channels
NumOfChannels = 0; % counts how many loops where ChannelName is found
i = 0; % used to increment the loop--in this case the first channel is Chan.0
char_fcsheader_main = char(fcsheader_main);
ChannelName = contains(char_fcsheader_main', ['Chan.',num2str(i)]); % get first value to start loop
while ChannelName == 1 % loop only runs if ChannelName is found is fcsheader
    ChannelName = contains(char_fcsheader_main', ['Chan.',num2str(i)]);
    if ChannelName == 1 % NumOfChannels only recorded if ChannelName is found in fcsheader
        NumOfChannels = NumOfChannels + 1;
    end
    i = i + 1;
end
Channel = struct('Label', cell(1, NumOfChannels), 'DataChannel', cell(1, NumOfChannels), 'Filter', ...
    cell(1, NumOfChannels), 'Detector', cell(1, NumOfChannels), 'Voltages', cell(1, NumOfChannels), ...
    'BlankSub', cell(1, NumOfChannels), 'Threshold', cell(1, NumOfChannels), 'BlankLevel', ...
    cell(1, NumOfChannels), 'BlankSD', cell(1, NumOfChannels), 'SN', cell(1, NumOfChannels));
Label       = get_mnemonic_value_special('Label', fcsheader_main, mnemonic_separator, NumOfChannels);
DataChannel = get_mnemonic_value_special('Data Chan.', fcsheader_main, mnemonic_separator, NumOfChannels);
Filter      = get_mnemonic_value_special('Filter', fcsheader_main, mnemonic_separator, NumOfChannels);
Detector    = get_mnemonic_value_special('Detector', fcsheader_main, mnemonic_separator, NumOfChannels);
Voltage     = get_mnemonic_value_special('Voltages', fcsheader_main, mnemonic_separator, NumOfChannels);
BlankSub    = get_mnemonic_value_special('Blank Sub', fcsheader_main, mnemonic_separator, NumOfChannels);
Threshold   = get_mnemonic_value_special('Threthod', fcsheader_main, mnemonic_separator, NumOfChannels);
BlankLevel  = get_mnemonic_value_special('Blank Level', fcsheader_main, mnemonic_separator, NumOfChannels);
BlankSD     = get_mnemonic_value_special('Blank SD', fcsheader_main, mnemonic_separator, NumOfChannels);
SN          = get_mnemonic_value_special('S/N', fcsheader_main, mnemonic_separator, NumOfChannels);
for i = 1:NumOfChannels
    Channel(i).Label       = Label{i};
    Channel(i).DataChannel = DataChannel{i};
    Channel(i).Filter      = Filter{i};
    Channel(i).Detector    = Detector{i};
    Channel(i).Voltages    = Voltage{i};
    Channel(i).BlankSub    = BlankSub{i};
    Channel(i).Threshold   = Threshold{i};
    Channel(i).BlankLevel  = BlankLevel{i};
    Channel(i).BlankSD     = BlankSD{i};
    Channel(i).SN          = SN{i};
end
end

function mneval = get_mnemonic_value(mnemonic_name, fcsheader, mnemonic_separator)
% Adds mnemonic separator to end as mnemonic name can appear more than once
% in fcsheader
mnemonic_separator = double(mnemonic_separator);
mnemonic_name = double(mnemonic_name); % convert to decimals
mnemonic_name = [mnemonic_name mnemonic_separator]; % add mnemonic separator to end which specifies which name
mnemonic_name = char(mnemonic_name); % convert back to characters to search through fcsheader
mnemonic_startpos = strfind(char(fcsheader'), mnemonic_name); % finds the mnemonic name in the fcsheader
if isempty(mnemonic_startpos) % if the mnemonic name is not found, return the null array
    mneval = [];
    return;
else
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_separators = strfind(char(fcsheader(mnemonic_stoppos:end)'), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    if isempty(next_separators) % for the case at the end of the header where no other mnemonic separators exist
        mneval = char(fcsheader(mnemonic_stoppos:length(fcsheader))'); % reads to end of fcsheader instead of next mnemonic separator
    else
        next_separator = next_separators(1) + mnemonic_stoppos; % the next mnemonic separator
        mneval = char(fcsheader(mnemonic_stoppos:next_separator - 2)');
    end
end
end

function mneval = get_mnemonic_value_special(mnemonic_name, fcsheader, mnemonic_separator, NumOfChannels)
% Reads for as many menmonic separators that are passed in from
% NumOfChannels
mnemonic_separator = double(mnemonic_separator);
mnemonic_name = double(mnemonic_name); % convert to decimals
mnemonic_name = [mnemonic_name mnemonic_separator]; % add mnemonic separator to end which specifies which name
mnemonic_name = char(mnemonic_name); % convert back to characters to search through fcsheader
mnemonic_startpos = strfind(char(fcsheader'), mnemonic_name); % finds the mnemonic name in the fcsheader
if isempty(mnemonic_startpos) % if the mnemonic name is not found, return the null array
    %mneval = [];
    mneval = '';
    return;
else
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_separators = strfind(char(fcsheader(mnemonic_stoppos:end)'), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    next_separator = next_separators(NumOfChannels) + mnemonic_stoppos; % the next mnemonic separator
    first_mneval = char(fcsheader(mnemonic_stoppos:next_separator - 2)');
    mneval = regexp(first_mneval, char(mnemonic_separator), 'split');
end
end