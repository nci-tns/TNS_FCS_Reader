function [fcshdr, Par, Misc, Laser] = AttuneNxT(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays
% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
fcshdr.SYS           = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
fcshdr.INST          = get_mnemonic_value('$INST',fcsheader_main, mnemonic_separator);
fcshdr.OP            = get_mnemonic_value('$OP',fcsheader_main, mnemonic_separator);
fcshdr.DATE          = get_mnemonic_value('$DATE',fcsheader_main, mnemonic_separator);
fcshdr.BTIM          = get_mnemonic_value('$BTIM',fcsheader_main, mnemonic_separator);
fcshdr.ETIM          = get_mnemonic_value('$ETIM',fcsheader_main, mnemonic_separator);
fcshdr.EXP           = get_mnemonic_value('$EXP',fcsheader_main, mnemonic_separator);
fcshdr.PROJ          = get_mnemonic_value('$PROJ',fcsheader_main, mnemonic_separator);
fcshdr.CELLS         = get_mnemonic_value('$CELLS',fcsheader_main, mnemonic_separator);
fcshdr.SMNO          = get_mnemonic_value('$SMNO',fcsheader_main, mnemonic_separator);
fcshdr.SRC           = get_mnemonic_value('$SRC',fcsheader_main, mnemonic_separator);
fcshdr.MODE          = get_mnemonic_value('$MODE',fcsheader_main, mnemonic_separator);
fcshdr.LOST          = get_mnemonic_value('$LOST',fcsheader_main, mnemonic_separator);
fcshdr.ABRT          = get_mnemonic_value('$ABRT',fcsheader_main, mnemonic_separator);
fcshdr.CYTSN         = get_mnemonic_value('$CYTSN', fcsheader_main, mnemonic_separator);
fcshdr.COM           = get_mnemonic_value('$COM', fcsheader_main, mnemonic_separator);
fcshdr.LAST_MODIFIED = get_mnemonic_value('$LAST_MODIFIED', fcsheader_main, mnemonic_separator);
fcshdr.LAST_MODIFIER = get_mnemonic_value('$LAST_MODIFIER', fcsheader_main, mnemonic_separator);
fcshdr.ORIGINALITY   = get_mnemonic_value('$ORIGINALITY', fcsheader_main, mnemonic_separator);
fcshdr.SPILLOVER     = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);
fcshdr.TIMESTEP      = get_mnemonic_value('$TIMESTEP', fcsheader_main, mnemonic_separator);
fcshdr.VOL           = get_mnemonic_value('$VOL', fcsheader_main, mnemonic_separator);
fcshdr.FIL           = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);

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
    'Bit', cell(1, NumOfPar), 'OpticalFilter', cell(1, NumOfPar), 'LaserLine', cell(1, NumOfPar), ...
    'Voltage', cell(1, NumOfPar), 'Gain', cell(1, NumOfPar), 'Log', cell(1, NumOfPar), 'Decade', ...
    cell(1, NumOfPar), 'Logzero', cell(1, NumOfPar), 'Amp', cell(1, NumOfPar));
for i=1:NumOfPar
    Par(i).Name          = get_mnemonic_value(['$P',num2str(i),'N'], fcsheader_main, mnemonic_separator);
    Par(i).Stain         = get_mnemonic_value(['$P',num2str(i),'S'], fcsheader_main, mnemonic_separator);
    Par(i).Range         = get_mnemonic_value(['$P',num2str(i),'R'], fcsheader_main, mnemonic_separator);
    Par(i).Bit           = get_mnemonic_value(['$P',num2str(i),'B'], fcsheader_main, mnemonic_separator);
    Par(i).OpticalFilter = get_mnemonic_value(['$P',num2str(i),'F'], fcsheader_main, mnemonic_separator);
    Par(i).LaserLine     = get_mnemonic_value(['$P',num2str(i),'L'], fcsheader_main, mnemonic_separator);
    Par(i).Voltage       = get_mnemonic_value(['$P',num2str(i),'V'], fcsheader_main, mnemonic_separator);
    Par(i).Gain          = get_mnemonic_value(['$P',num2str(i),'G'], fcsheader_main, mnemonic_separator);
    Par(i).Amp           = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    
   %LIN/LOG
   % In FCS 3.1, all floating data is treated as LIN rather than LOG for $PiE--
   % all $PiE are stored as 0.0, 0.0--nothing indicates LOG or LIN
    islogpar = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    if strcmp(islogpar, '0,0')
        par_exponent_str = '0,0';
    else % islogpar = LOG case
        par_exponent_str = '5,1';
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
Misc.TR1            = get_mnemonic_value('#TR1',fcsheader_main, mnemonic_separator);
Misc.FLOWRATE       = get_mnemonic_value('#FLOWRATE', fcsheader_main, mnemonic_separator);
Misc.LASERCONFIG    = get_mnemonic_value('#LASERCONFIG', fcsheader_main, mnemonic_separator);
Misc.P1Label        = get_mnemonic_value('#P1Label', fcsheader_main, mnemonic_separator);
Misc.P1Target       = get_mnemonic_value('#P1Target', fcsheader_main, mnemonic_separator);
Misc.PTDATE         = get_mnemonic_value('#PTDATE', fcsheader_main, mnemonic_separator);
Misc.PTRESULT       = get_mnemonic_value('#PTRESULT', fcsheader_main, mnemonic_separator);
Misc.WIDTHTHRESHOLD = get_mnemonic_value('#WIDTHTHRESHOLD', fcsheader_main, mnemonic_separator);
Misc.WINEXT         = get_mnemonic_value('#WINEXT', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA      = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA        = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS  = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS    = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT      = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT        = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
Misc.NEXTDATA       = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);

% Lasers
NumOfLasers = 0; % counts how many loops where LaserColor is found
i = 1; % used to increment the loop
LaserColor = get_mnemonic_value(['#LASER',num2str(i),'COLOR'], fcsheader_main, mnemonic_separator); % get first value to start loop
while ~isempty(LaserColor) % loop only runs if LaserColor is found
    LaserColor = get_mnemonic_value(['#LASER',num2str(i),'COLOR'], fcsheader_main, mnemonic_separator);
    if ~isempty(LaserColor) % NumofChannels only recorded if LaserColor is not empty
        NumOfLasers = NumOfLasers + 1;
    end
    i = i + 1;
end
Laser = struct('COLOR', cell(1, NumOfLasers), 'DELAY', cell(1, NumOfLasers), 'ASF', cell(1, NumOfLasers));
for i = 1:NumOfLasers
    Laser(i).COLOR = get_mnemonic_value(['#LASER',num2str(i),'COLOR'], fcsheader_main, mnemonic_separator);
    Laser(i).DELAY = get_mnemonic_value(['#LASER',num2str(i),'DELAY'], fcsheader_main, mnemonic_separator);
    Laser(i).ASF   = get_mnemonic_value(['#LASER',num2str(i),'ASF'], fcsheader_main, mnemonic_separator);
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
    next_separators = strfind(char(fcsheader(mnemonic_stoppos+1:end)'), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    if contains(mnemonic_name, 'P') && contains(mnemonic_name, 'F') % the case for $P(i)F as they store Optical Filters using mnemonic separators
        next_separator = next_separators(3) + mnemonic_stoppos; % the third mnemonic separator
        mneval = char(fcsheader(mnemonic_stoppos:next_separator-1)');
        if length(mneval) > 7 % in cases for $P(i)F where no Optical Filter is used, this prevents returning meaningless data
            %mneval = [];
            mneval = '';
        end
    else
        next_separator = next_separators(1) + mnemonic_stoppos; % the next mnemonic separator
        mneval = char(fcsheader(mnemonic_stoppos:next_separator-1)');
    end
end    
end