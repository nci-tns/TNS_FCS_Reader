function [fcshdr, Par, Misc, Laser] = Fortessa(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays
% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
fcshdr.SYS      = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
fcshdr.INST     = get_mnemonic_value('$INST', fcsheader_main, mnemonic_separator);
fcshdr.OP       = get_mnemonic_value('$OP', fcsheader_main, mnemonic_separator);
fcshdr.DATE     = get_mnemonic_value('$DATE', fcsheader_main, mnemonic_separator);
fcshdr.BTIM     = get_mnemonic_value('$BTIM', fcsheader_main, mnemonic_separator);
fcshdr.ETIM     = get_mnemonic_value('$ETIM', fcsheader_main, mnemonic_separator);
fcshdr.SRC      = get_mnemonic_value('$SRC', fcsheader_main, mnemonic_separator);
fcshdr.MODE     = get_mnemonic_value('$MODE', fcsheader_main, mnemonic_separator);
fcshdr.TIMESTEP = get_mnemonic_value('$TIMESTEP', fcsheader_main, mnemonic_separator);
fcshdr.FIL      = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);
if isempty(fcshdr.CYT) % this is empty in the uOttawa LSRFortessa file
    fcshdr.CYT = 'Fortessa--Unknown';
end

% Comp Matrix Reader
fcshdr.COMP = get_mnemonic_value('SPILL', fcsheader_main, mnemonic_separator);
comp = get_mnemonic_value('SPILL', fcsheader_main, mnemonic_separator);
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
    
    % LIN/LOG
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

% Micellaneous
Misc.CREATOR                      = get_mnemonic_value('CREATOR', fcsheader_main, mnemonic_separator);
Misc.TUBE_NAME                    = get_mnemonic_value('TUBE NAME', fcsheader_main, mnemonic_separator);
Misc.EXPERIMENT_NAME              = get_mnemonic_value('EXPERIMENT NAME', fcsheader_main, mnemonic_separator);
Misc.GUID                         = get_mnemonic_value('GUID', fcsheader_main, mnemonic_separator);
Misc.CYTNUM                       = get_mnemonic_value('CYTNUM', fcsheader_main, mnemonic_separator);
Misc.WINDOW_EXTENSION             = get_mnemonic_value('WINDOW EXTENSION', fcsheader_main, mnemonic_separator);
Misc.EXPORT_USER_NAME             = get_mnemonic_value('EXPORT USER NAME', fcsheader_main, mnemonic_separator);
Misc.EXPORT_TIME                  = get_mnemonic_value('EXPORT TIME', fcsheader_main, mnemonic_separator);
Misc.FSC_ASF                      = get_mnemonic_value('FSC ASF', fcsheader_main, mnemonic_separator);
Misc.AUTOBS                       = get_mnemonic_value('AUTOBS', fcsheader_main, mnemonic_separator);
Misc.SPILL                        = get_mnemonic_value('SPILL', fcsheader_main, mnemonic_separator);
Misc.APPLY_COMPENSATION           = get_mnemonic_value('APPLY COMPENSATION', fcsheader_main, mnemonic_separator);
Misc.THRESHOLD                    = get_mnemonic_value('THRESHOLD', fcsheader_main, mnemonic_separator);
Misc.SAMPLE_ID                    = get_mnemonic_value('SAMPLE ID', fcsheader_main, mnemonic_separator);
Misc.PATIENT_ID                   = get_mnemonic_value('PATIENT ID', fcsheader_main, mnemonic_separator);
Misc.SETTINGS                     = get_mnemonic_value('SETTINGS', fcsheader_main, mnemonic_separator);
Misc.PLATE_NAME                   = get_mnemonic_value('PLATE NAME', fcsheader_main, mnemonic_separator);
Misc.WELL_ID                      = get_mnemonic_value('WELL ID', fcsheader_main, mnemonic_separator);
Misc.PLATE_ID                     = get_mnemonic_value('PLATE ID', fcsheader_main, mnemonic_separator);
Misc.CST_SETUP_STATUS             = get_mnemonic_value('CST SETUP STATUS', fcsheader_main, mnemonic_separator);
Misc.CST_BEADS_LOT_ID             = get_mnemonic_value('CST BEADS LOT ID', fcsheader_main, mnemonic_separator);
Misc.CYTOMETER_CONFIG_NAME        = get_mnemonic_value('CYTOMETER CONFIG NAME', fcsheader_main, mnemonic_separator);
Misc.CYTOMETER_CONFIG_CREATE_DATE = get_mnemonic_value('CYTOMETER CONFIG CREATE DATE', fcsheader_main, mnemonic_separator);
Misc.CST_SETUP_DATE               = get_mnemonic_value('CST SETUP DATE', fcsheader_main, mnemonic_separator);
Misc.CST_BASELINE_DATE            = get_mnemonic_value('CST BASELINE DATE', fcsheader_main, mnemonic_separator);
Misc.CST_BEADS_EXPIRED            = get_mnemonic_value('CST BEADS EXPIRED', fcsheader_main, mnemonic_separator);
Misc.CST_PERFORMANCE_EXPIRED      = get_mnemonic_value('CST PERFORMANCE EXPIRED', fcsheader_main, mnemonic_separator);
Misc.CST_REGULATORY_STATUS        = get_mnemonic_value('CST REGULATORY STATUS', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA                    = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA                      = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS                = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS                  = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT                    = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT                      = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
Misc.NEXTDATA                     = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);

% Lasers
NumOfLasers = 0; % counts how many loops where LaserName is found
i = 1; % used to increment the loop
LaserName = get_mnemonic_value(['LASER',num2str(i),'NAME'], fcsheader_main, mnemonic_separator); % get first value to start loop
while ~isempty(LaserName) % loop only runs if LaserName is found
    LaserName = get_mnemonic_value(['LASER',num2str(i),'NAME'], fcsheader_main, mnemonic_separator);
    if ~isempty(LaserName) % NumofLasers only recorded if LaserName is not empty
        NumOfLasers = NumOfLasers + 1;
    end
    i = i + 1;
end
Laser = struct('NAME', cell(1, NumOfLasers), 'DELAY', cell(1, NumOfLasers), 'ASF', cell(1, NumOfLasers));
for i = 1:NumOfLasers
    Laser(i).NAME  = get_mnemonic_value(['LASER',num2str(i),'NAME'], fcsheader_main, mnemonic_separator);
    Laser(i).DELAY = get_mnemonic_value(['LASER',num2str(i),'DELAY'], fcsheader_main, mnemonic_separator);
    Laser(i).ASF   = get_mnemonic_value(['LASER',num2str(i),'ASF'], fcsheader_main, mnemonic_separator);
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