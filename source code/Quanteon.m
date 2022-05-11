function [fcshdr, Par, Misc] = Quanteon(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays
% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
fcshdr.OP        = get_mnemonic_value('$OP', fcsheader_main, mnemonic_separator);
fcshdr.DATE      = get_mnemonic_value('$DATE', fcsheader_main, mnemonic_separator);
fcshdr.BTIM      = get_mnemonic_value('$BTIM', fcsheader_main, mnemonic_separator);
fcshdr.ETIM      = get_mnemonic_value('$ETIM', fcsheader_main, mnemonic_separator);
fcshdr.PROJ      = get_mnemonic_value('$PROJ', fcsheader_main, mnemonic_separator);
fcshdr.SMNO      = get_mnemonic_value('$SMNO', fcsheader_main, mnemonic_separator);
fcshdr.SRC       = get_mnemonic_value('$SRC', fcsheader_main, mnemonic_separator);
fcshdr.MODE      = get_mnemonic_value('$MODE', fcsheader_main, mnemonic_separator);
fcshdr.TR        = get_mnemonic_value('$TR', fcsheader_main, mnemonic_separator);
fcshdr.VOL       = get_mnemonic_value('$VOL', fcsheader_main, mnemonic_separator);
fcshdr.WELLID    = get_mnemonic_value('$WELLID', fcsheader_main, mnemonic_separator);
fcshdr.PLATEID   = get_mnemonic_value('$PLATEID', fcsheader_main, mnemonic_separator);
fcshdr.LOST      = get_mnemonic_value('$LOST', fcsheader_main, mnemonic_separator);
fcshdr.TIMESTEP  = get_mnemonic_value('$TIMESTEP', fcsheader_main, mnemonic_separator);
fcshdr.CYTSN     = get_mnemonic_value('$CYTSN', fcsheader_main, mnemonic_separator);
fcshdr.SPILLOVER = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);
fcshdr.UNICODE   = get_mnemonic_value('$UNICODE', fcsheader_main, mnemonic_separator);
fcshdr.FIL       = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);

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
Par = struct('Name', cell(1, NumOfPar), 'Stain', cell(1, NumOfPar), 'Range', cell(1, NumOfPar), ...
    'Bit', cell(1, NumOfPar), 'LaserLine', cell(1, NumOfPar), 'ExcitationOutput', cell(1, NumOfPar), ...
    'Voltage', cell(1, NumOfPar), 'Gain_NC', cell(1, NumOfPar), 'C', cell(1, NumOfPar),...
    'Log', cell(1, NumOfPar), 'Decade', cell(1, NumOfPar), 'Logzero', cell(1, NumOfPar), 'Display', ...
    cell(1, NumOfPar));
for i=1:NumOfPar
    Par(i).Name             = get_mnemonic_value(['$P',num2str(i),'N'], fcsheader_main, mnemonic_separator);
    Par(i).Stain            = get_mnemonic_value(['$P',num2str(i),'S'], fcsheader_main, mnemonic_separator);
    Par(i).Range            = get_mnemonic_value(['$P',num2str(i),'R'], fcsheader_main, mnemonic_separator);
    Par(i).Bit              = get_mnemonic_value(['$P',num2str(i),'B'], fcsheader_main, mnemonic_separator);
    Par(i).LaserLine        = get_mnemonic_value(['$P',num2str(i),'L'], fcsheader_main, mnemonic_separator);
    Par(i).ExcitationOutput = get_mnemonic_value(['$P',num2str(i),'O'], fcsheader_main, mnemonic_separator);
    Par(i).Voltage          = get_mnemonic_value(['$P',num2str(i),'V'], fcsheader_main, mnemonic_separator);
    Par(i).Gain_NC          = get_mnemonic_value(['#NCP',num2str(i),'G'], fcsheader_main, mnemonic_separator);
    Par(i).C                = get_mnemonic_value(['#NCP',num2str(i-1),'C'], fcsheader_main, mnemonic_separator); % not sure why this parameter starts at 0
    Par(i).Display          = get_mnemonic_value(['$P',num2str(i),'D'], fcsheader_main, mnemonic_separator);
    
    %LIN/LOG
    % In FCS 3.1, all floating data is treated as LIN rather than LOG for $PiE--
    % all $PiE are stored as 0.0, 0.0--nothing indicates LOG or LIN
    islogpar = get_mnemonic_value(['$P',num2str(i),'D'], fcsheader_main, mnemonic_separator);
    if contains(islogpar, 'Linear')
        par_exponent_str = '0,0'; % this ignores what is stored after linear--not sure if this is desired 
    else % islogpar = LOG case
        logsplit = strsplit(islogpar, ',');
        par_exponent_str = strcat(logsplit{2}, ',', logsplit{3});
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
Misc.NCCreator               = get_mnemonic_value('#NCCreator', fcsheader_main, mnemonic_separator);
Misc.NCUnlimits              = get_mnemonic_value('#NCUnlimits', fcsheader_main, mnemonic_separator);
Misc.NCEventsLimits          = get_mnemonic_value('#NCEventsLimits', fcsheader_main, mnemonic_separator);
Misc.NCTimeLimits            = get_mnemonic_value('#NCTimeLimits', fcsheader_main, mnemonic_separator);
Misc.NCVolumeLimits          = get_mnemonic_value('#NCVolumeLimits', fcsheader_main, mnemonic_separator);
Misc.NCFlowRate              = get_mnemonic_value('#NCFlowRate', fcsheader_main, mnemonic_separator);
Misc.NCFLConfig              = get_mnemonic_value('#NCFLConfig', fcsheader_main, mnemonic_separator);
Misc.NCSoftware              = get_mnemonic_value('#NCSoftware', fcsheader_main, mnemonic_separator);
Misc.NCVersion               = get_mnemonic_value('#NCVersion', fcsheader_main, mnemonic_separator);
Misc.NCCytometerInfo         = get_mnemonic_value('#NCCytometerInfo', fcsheader_main, mnemonic_separator);
Misc.NCTestMode              = get_mnemonic_value('#NCTestMode', fcsheader_main, mnemonic_separator);
Misc.NCStatusSheath          = get_mnemonic_value('#NCStatusSheath', fcsheader_main, mnemonic_separator);
Misc.NCStatusCleaner         = get_mnemonic_value('#NCStatusCleaner', fcsheader_main, mnemonic_separator);
Misc.NCStatusDecontamination = get_mnemonic_value('#NCStatusDecontamination', fcsheader_main, mnemonic_separator);
Misc.NCStatusWaste           = get_mnemonic_value('#NCStatusWaste', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA               = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA                 = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS           = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS             = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT               = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT                 = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
Misc.NEXTDATA                = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);

%Status
NumOfLasers = 0; % counts how many loops where #NCStatusLaser is found
i = 1; % used to increment the loop
char_fcsheader_main = char(fcsheader_main);
LaserName = contains(char_fcsheader_main', ['#NCStatusLaser', num2str(i)]); % get first value to start loop
while LaserName == 1 % loop only runs if LaserName is found is fcsheader
    LaserName = contains(char_fcsheader_main', ['#NCStatusLaser', num2str(i)]);
    if LaserName == 1 % NumOfLasers only recorded if LaserName is found in fcsheader
        NumOfLasers = NumOfLasers + 1;
    end
    i = i + 1;
end
for i = 1:NumOfLasers
    Misc.StatusLaser(i).Laser = get_mnemonic_value(['#NCStatusLaser', num2str(i)], fcsheader_main, mnemonic_separator);
end
NumOfPMTs = 0; % counts how many loops where #NCStatusPMT is found
i = 1; % used to increment the loop
PMTName = contains(char_fcsheader_main', ['#NCStatusPMT', num2str(i)]); % get first value to start loop
while PMTName == 1 % loop only runs if PMTName) is found is fcsheader
    PMTName = contains(char_fcsheader_main', ['#NCStatusPMT', num2str(i)]);
    if PMTName == 1 % NumOfPMTs only recorded if PMTName is found in fcsheader
        NumOfPMTs = NumOfPMTs + 1;
    end
    i = i + 1;
end
for i = 1:NumOfPMTs
    Misc.StatusPMT(i).PMT = get_mnemonic_value(['#NCStatusPMT', num2str(i)], fcsheader_main, mnemonic_separator);
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
    if contains(mneval, '$') && contains(mnemonic_name, 'NCStatusWaste')
        mneval = char(fcsheader(mnemonic_stoppos(2):next_separator(2))');
    else
    end
end
end