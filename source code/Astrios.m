function [fcshdr, Par, Misc] = Astrios(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays
% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
fcshdr.SYS       = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
fcshdr.INST      = get_mnemonic_value('$INST', fcsheader_main, mnemonic_separator);
fcshdr.OP        = get_mnemonic_value('$OP', fcsheader_main, mnemonic_separator);
fcshdr.DATE      = get_mnemonic_value('$DATE', fcsheader_main, mnemonic_separator);
fcshdr.BTIM      = get_mnemonic_value('$BTIM', fcsheader_main, mnemonic_separator);
fcshdr.ETIM      = get_mnemonic_value('$ETIM', fcsheader_main, mnemonic_separator);
fcshdr.PROJ      = get_mnemonic_value('$PROJ', fcsheader_main, mnemonic_separator);
fcshdr.SMNO      = get_mnemonic_value('$SMNO', fcsheader_main, mnemonic_separator);
fcshdr.SRC       = get_mnemonic_value('$SRC', fcsheader_main, mnemonic_separator);
fcshdr.MODE      = get_mnemonic_value('$MODE', fcsheader_main, mnemonic_separator);
fcshdr.TR        = get_mnemonic_value('$TR', fcsheader_main, mnemonic_separator);
fcshdr.LOST      = get_mnemonic_value('$LOST', fcsheader_main, mnemonic_separator);
fcshdr.TIMESTEP  = get_mnemonic_value('$TIMESTEP', fcsheader_main, mnemonic_separator);
fcshdr.SPILLOVER = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);
fcshdr.FIL       = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);

% Parameters
NumOfPar = str2double(get_mnemonic_value('$PAR', fcsheader_main, mnemonic_separator));
Par = struct('Name', cell(1, NumOfPar), 'Stain', cell(1, NumOfPar), 'Range', cell(1, NumOfPar), ...
    'Bit', cell(1, NumOfPar), 'OpticalFilter', cell(1, NumOfPar), 'LaserLine', cell(1, NumOfPar), ...
    'Percent', cell(1, NumOfPar), 'Voltage', cell(1, NumOfPar), 'Gain', cell(1, NumOfPar), ...
    'Log', cell(1, NumOfPar), 'Decade', cell(1, NumOfPar), 'Logzero', cell(1, NumOfPar), 'Amp', ...
    cell(1, NumOfPar));
for i=1:NumOfPar
    Par(i).Name          = get_mnemonic_value(['$P',num2str(i),'N'], fcsheader_main, mnemonic_separator);
    Par(i).Stain         = get_mnemonic_value(['$P',num2str(i),'S'], fcsheader_main, mnemonic_separator);
    Par(i).Range         = get_mnemonic_value(['$P',num2str(i),'R'], fcsheader_main, mnemonic_separator);
    Par(i).Bit           = get_mnemonic_value(['$P',num2str(i),'B'], fcsheader_main, mnemonic_separator);
    Par(i).OpticalFilter = get_mnemonic_value(['$P',num2str(i),'F'], fcsheader_main, mnemonic_separator);
    Par(i).LaserLine     = get_mnemonic_value(['$P',num2str(i),'L'], fcsheader_main, mnemonic_separator);
    Par(i).Percent       = get_mnemonic_value(['$P',num2str(i),'P'], fcsheader_main, mnemonic_separator);
    Par(i).Voltage       = get_mnemonic_value(['$P',num2str(i),'V'], fcsheader_main, mnemonic_separator);
    Par(i).Gain          = get_mnemonic_value(['$P',num2str(i),'G'], fcsheader_main, mnemonic_separator);
    Par(i).Amp           = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    
    %LIN/LOG
    % In FCS 3.1, all floating data is treated as LIN rather than LOG for $PiE--
    % all $PiE are stored as 0.0, 0.0--nothing indicates LOG or LIN
    islogpar = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    if strcmp(islogpar, '0.0,0.0')
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
Misc.SAMPLEID          = get_mnemonic_value('SAMPLEID', fcsheader_main, mnemonic_separator);
Misc.WIDTHPARAMUPSHIFT = get_mnemonic_value('WIDTHPARAMUPSHIFT', fcsheader_main, mnemonic_separator);
Misc.SOFTWAREREVISION  = get_mnemonic_value('SOFTWAREREVISION', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA         = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA           = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS     = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS       = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT         = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT           = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
Misc.NEXTDATA          = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);
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