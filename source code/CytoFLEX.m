function [fcshdr, Par, Misc, Channel] = CytoFLEX(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays.
% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
fcshdr.SYS       = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
fcshdr.OP        = get_mnemonic_value('$OP', fcsheader_main, mnemonic_separator);
fcshdr.DATE      = get_mnemonic_value('$DATE', fcsheader_main, mnemonic_separator);
fcshdr.BTIM      = get_mnemonic_value('$BTIM', fcsheader_main, mnemonic_separator);
fcshdr.ETIM      = get_mnemonic_value('$ETIM', fcsheader_main, mnemonic_separator);
fcshdr.MODE      = get_mnemonic_value('$MODE', fcsheader_main, mnemonic_separator);
fcshdr.LOST      = get_mnemonic_value('$LOST', fcsheader_main, mnemonic_separator);
fcshdr.ABRT      = get_mnemonic_value('$ABRT', fcsheader_main, mnemonic_separator);
fcshdr.CYTSN     = get_mnemonic_value('$CYTSN', fcsheader_main, mnemonic_separator);
fcshdr.SPILLOVER = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);
fcshdr.TIMESTEP  = get_mnemonic_value('$TIMESTEP', fcsheader_main, mnemonic_separator);
fcshdr.VOL       = get_mnemonic_value('$VOL', fcsheader_main, mnemonic_separator);
fcshdr.FIL       = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);

if isempty(fcshdr.CYT) && ~isempty(fcshdr.OP)

    fcshdr.CYT = fcshdr.OP;

end

if sum(contains(fcshdr.CYT, 'CytoFLEX', 'IgnoreCase', true)) == 0

    fcshdr.CYT = 'CytoFLEX';

end

% Comp Matrix Reader
comp = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);
if ~isempty(comp)
    compcell = regexp(comp,',','split');
    nc = str2double(compcell{1}); % tells how many CompLabels there are and the size of the matrix
    if isnan(nc) % added to stop errors occuring with aurora
    else
        fcshdr.CompLabels = compcell(2:nc+1);
        fcshdr.CompMat = reshape(str2double(compcell(nc+2:end)'),[nc nc])'; 
    end
else
    fcshdr.CompLabels = [];
    fcshdr.CompMat = [];
end

% Parameters
% Runs a loop through all parameters to read their mnemonic names
NumOfPar = str2double(get_mnemonic_value('$PAR', fcsheader_main, mnemonic_separator));
Par = struct('Name', cell(1, NumOfPar), 'Stain', cell(1, NumOfPar), 'Range', ...
    cell(1, NumOfPar), 'Bit', cell(1, NumOfPar), 'Gain', cell(1, NumOfPar), ...
    'Log', cell(1, NumOfPar), 'Decade', cell(1, NumOfPar), 'Logzero', cell(1, NumOfPar), ...
    'Display_', cell(1, NumOfPar), 'Amp', cell(1, NumOfPar));
for i=1:NumOfPar
    Par(i).Name     = get_mnemonic_value(['$P',num2str(i),'N'], fcsheader_main, mnemonic_separator);
    Par(i).Stain    = get_mnemonic_value(['$P',num2str(i),'S'], fcsheader_main, mnemonic_separator);
    Par(i).Range    = get_mnemonic_value(['$P',num2str(i),'R'], fcsheader_main, mnemonic_separator);
    Par(i).Bit      = get_mnemonic_value(['$P',num2str(i),'B'], fcsheader_main, mnemonic_separator);
    Par(i).Gain     = get_mnemonic_value(['$P',num2str(i),'G'], fcsheader_main, mnemonic_separator);
    Par(i).Display_ = get_mnemonic_value(['P',num2str(i),'DISPLAY'], fcsheader_main, mnemonic_separator);
    Par(i).Amp      = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    
    %LIN/LOG
    % In FCS 3.1, all floating data is treated as LIN rather than LOG for $PiE--so all $PiE are stored as 0,0,
    % so use PiDISPLAY and an assumed decade of 5--not sure what is desired here
    islogpar = get_mnemonic_value(['P',num2str(i),'DISPLAY'], fcsheader_main, mnemonic_separator);
    if strcmp(islogpar, 'LOG')
        par_exponent_str = '5,1'; % arbitrary
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

% Micellaneous
Misc.FILVER        = get_mnemonic_value('FILVER', fcsheader_main, mnemonic_separator);
Misc.CYTEXPERTFIL  = get_mnemonic_value('CYTEXPERTFIL', fcsheader_main, mnemonic_separator);
Misc.TBID          = get_mnemonic_value('TBID', fcsheader_main, mnemonic_separator);
Misc.TBNM          = get_mnemonic_value('TBNM', fcsheader_main, mnemonic_separator);
Misc.RCTOT         = get_mnemonic_value('RCTOT', fcsheader_main, mnemonic_separator);
Misc.USRCTOT       = get_mnemonic_value('USRCTOT', fcsheader_main, mnemonic_separator);
Misc.CGNM          = get_mnemonic_value('CGNM', fcsheader_main, mnemonic_separator);
Misc.CGID          = get_mnemonic_value('CGID', fcsheader_main, mnemonic_separator);
Misc.RCTIM         = get_mnemonic_value('RCTIM', fcsheader_main, mnemonic_separator);
Misc.USRCTIM       = get_mnemonic_value('USRCTIM', fcsheader_main, mnemonic_separator);
Misc.RCVOL         = get_mnemonic_value('RCVOL', fcsheader_main, mnemonic_separator);
Misc.USRCVOL       = get_mnemonic_value('USRCVOL', fcsheader_main, mnemonic_separator);
Misc.IMPTTB        = get_mnemonic_value('IMPTTB', fcsheader_main, mnemonic_separator);
Misc.FLLW          = get_mnemonic_value('FLLW', fcsheader_main, mnemonic_separator);
Misc.RCD           = get_mnemonic_value('RCD', fcsheader_main, mnemonic_separator);
Misc.DURTIM        = get_mnemonic_value('DURTIM', fcsheader_main, mnemonic_separator);
Misc.USCOMP        = get_mnemonic_value('USCOMP', fcsheader_main, mnemonic_separator);
Misc.AHCOMPSYNC    = get_mnemonic_value('AHCOMPSYNC', fcsheader_main, mnemonic_separator);
Misc.COMPCHH       = get_mnemonic_value('COMPCHH', fcsheader_main, mnemonic_separator);
Misc.COMPAFH       = get_mnemonic_value('COMPAFH', fcsheader_main, mnemonic_separator);
Misc.COMPH         = get_mnemonic_value('COMPH', fcsheader_main, mnemonic_separator);
Misc.COMPGAINH     = get_mnemonic_value('COMPGAINH', fcsheader_main, mnemonic_separator);
Misc.COMPCHA       = get_mnemonic_value('COMPCHA', fcsheader_main, mnemonic_separator);
Misc.COMPBGA       = get_mnemonic_value('COMPBGA', fcsheader_main, mnemonic_separator);
Misc.COMPAFA       = get_mnemonic_value('COMPAFA', fcsheader_main, mnemonic_separator);
Misc.COMPA         = get_mnemonic_value('COMPA', fcsheader_main, mnemonic_separator);
Misc.COMPGAINA     = get_mnemonic_value('COMPGAINA', fcsheader_main, mnemonic_separator);
Misc.SN            = get_mnemonic_value('SN', fcsheader_main, mnemonic_separator);
Misc.FLDSM         = get_mnemonic_value('FLDSM', fcsheader_main, mnemonic_separator);
Misc.CHAR          = get_mnemonic_value('CHAR', fcsheader_main, mnemonic_separator);
Misc.PCHID         = get_mnemonic_value('PCHID', fcsheader_main, mnemonic_separator);
Misc.PCHTP         = get_mnemonic_value('PCHTP', fcsheader_main, mnemonic_separator);
Misc.TRLGC         = get_mnemonic_value('TRLGC', fcsheader_main, mnemonic_separator);
Misc.WCH           = get_mnemonic_value('WCH', fcsheader_main, mnemonic_separator);
Misc.DGAIN         = get_mnemonic_value('DGAIN', fcsheader_main, mnemonic_separator);
Misc.SWVER         = get_mnemonic_value('SWVER', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA     = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA       = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS   = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT     = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT       = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
Misc.NEXTDATA      = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);

% Channels
NumOfChannels = 0; % counts how many loops where ChannelID is found
i = 1; % used to increment the loop
ChannelID = get_mnemonic_value(['CH',num2str(i),'ID'], fcsheader_main, mnemonic_separator); % get first value to start loop
while ~isempty(ChannelID) % loop only runs if ChannelID is found
    ChannelID = get_mnemonic_value(['CH',num2str(i),'ID'], fcsheader_main, mnemonic_separator);
    if ~isempty(ChannelID) % NumofChannels only recorded if ChannelID is not empty
        NumOfChannels = NumOfChannels + 1;
    end
    i = i + 1;
end
Channel = struct('ID', cell(1, NumOfChannels), 'NM', cell(1, NumOfChannels), ...
    'AD', cell(1, NumOfChannels), 'DA', cell(1, NumOfChannels), 'TH', ...
    cell(1, NumOfChannels), 'TR', cell(1, NumOfChannels), 'GAIN', cell(1, NumOfChannels), ...
    'USH', cell(1, NumOfChannels), 'DELAY', cell(1, NumOfChannels), 'DELTA', ...
    cell(1, NumOfChannels), 'THUS', cell(1, NumOfChannels), 'FL', cell(1, NumOfChannels), ...
    'HS', cell(1, NumOfChannels), 'AS', cell(1, NumOfChannels), 'FLNMS', ...
    cell(1, NumOfChannels), 'HATFL', cell(1, NumOfChannels), 'AATFL', cell(1, NumOfChannels), 'HAVAL', cell(1, NumOfChannels));
for i = 1:NumOfChannels
    Channel(i).ID    = get_mnemonic_value(['CH',num2str(i),'ID'], fcsheader_main, mnemonic_separator);
    Channel(i).NM    = get_mnemonic_value(['CH',num2str(i),'NM'], fcsheader_main, mnemonic_separator);
    Channel(i).AD    = get_mnemonic_value(['CH',num2str(i),'AD'], fcsheader_main, mnemonic_separator);
    Channel(i).DA    = get_mnemonic_value(['CH',num2str(i),'DA'], fcsheader_main, mnemonic_separator);
    Channel(i).TH    = get_mnemonic_value(['CH',num2str(i),'TH'], fcsheader_main, mnemonic_separator);
    Channel(i).TR    = get_mnemonic_value(['CH',num2str(i),'TR'], fcsheader_main, mnemonic_separator);
    Channel(i).GAIN  = get_mnemonic_value(['CH',num2str(i),'GAIN'], fcsheader_main, mnemonic_separator);
    Channel(i).USH   = get_mnemonic_value(['CH',num2str(i),'USH'], fcsheader_main, mnemonic_separator);
    Channel(i).DELAY = get_mnemonic_value(['CH',num2str(i),'DELAY'], fcsheader_main, mnemonic_separator);
    Channel(i).DELTA = get_mnemonic_value(['CH',num2str(i),'DELTA'], fcsheader_main, mnemonic_separator);
    Channel(i).THUS  = get_mnemonic_value(['CH',num2str(i),'THUS'], fcsheader_main, mnemonic_separator);
    Channel(i).FL    = get_mnemonic_value(['CH',num2str(i),'FL'], fcsheader_main, mnemonic_separator);
    Channel(i).HS    = get_mnemonic_value(['CH',num2str(i),'HS'], fcsheader_main, mnemonic_separator);
    Channel(i).AS    = get_mnemonic_value(['CH',num2str(i),'AS'],fcsheader_main, mnemonic_separator);
    Channel(i).FLNMS = get_mnemonic_value(['CH',num2str(i),'FLNMS'], fcsheader_main, mnemonic_separator);
    Channel(i).HATFL = get_mnemonic_value(['CH',num2str(i),'HATFL'], fcsheader_main, mnemonic_separator);
    Channel(i).AATFL = get_mnemonic_value(['CH',num2str(i),'AATFL'], fcsheader_main, mnemonic_separator);
    Channel(i).HAVAL = get_mnemonic_value(['CH',num2str(i),'HAVAL'], fcsheader_main, mnemonic_separator);
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
    %mneval = [];
    mneval = '';
    return;
else
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_separators = strfind(char(fcsheader(mnemonic_stoppos:end)'), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    next_separator = next_separators(1) + mnemonic_stoppos; % the next mnemonic separator
    mneval = char(fcsheader(mnemonic_stoppos:next_separator - 2)');
end
end