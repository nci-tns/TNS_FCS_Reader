function [fcshdr, Par, Misc, Laser] = ImageStream(fcsheader_main, fcshdr, mnemonic_separator)
% Gets the values for each mnemonic name as strings--will eventually need
% to write some strings to arrays
% Replace instances of mnemonic separators in a row
fcsheader_main = strrep(char(fcsheader_main'), '//', '_'); % prevents reading double // as a mnemonic separator

% Standardized FCS Header
% $FIL stored in Misc as it can be different from the filepath--called OriginalFilePath as this is the filepath when it was written
fcshdr.DATE        = get_mnemonic_value('$DATE', fcsheader_main, mnemonic_separator);
fcshdr.BTIM        = get_mnemonic_value('$BTIM', fcsheader_main, mnemonic_separator);
fcshdr.ETIM        = get_mnemonic_value('$ETIM', fcsheader_main, mnemonic_separator);
fcshdr.MODE        = get_mnemonic_value('$MODE', fcsheader_main, mnemonic_separator);
fcshdr.CYTSN       = get_mnemonic_value('$CYTSN', fcsheader_main, mnemonic_separator);
fcshdr.ORIGINALITY = get_mnemonic_value('$ORIGINALITY', fcsheader_main, mnemonic_separator);
fcshdr.PROJ        = get_mnemonic_value('$PROJ', fcsheader_main, mnemonic_separator);
fcshdr.VOL         = get_mnemonic_value('$VOL', fcsheader_main, mnemonic_separator);
fcshdr.FIL         = get_mnemonic_value('$FIL', fcsheader_main, mnemonic_separator);
fcshdr.SPILLOVER   = get_mnemonic_value('$SPILLOVER', fcsheader_main, mnemonic_separator);

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
NumOfPar = str2double(get_mnemonic_value('$PAR', fcsheader_main, mnemonic_separator));
Par = struct('Name', cell(1, NumOfPar), 'Range', cell(1, NumOfPar), 'Bit', ...
    cell(1, NumOfPar), 'Gain', cell(1, NumOfPar),'Log', cell(1, NumOfPar), ...
    'Decade', cell(1, NumOfPar), 'Logzero', cell(1, NumOfPar), 'Amp', cell(1, NumOfPar));
for i=1:NumOfPar
    Par(i).Name  = get_mnemonic_value(['$P',num2str(i),'N'], fcsheader_main, mnemonic_separator);
    Par(i).Range = get_mnemonic_value(['$P',num2str(i),'R'], fcsheader_main, mnemonic_separator);
    Par(i).Bit   = get_mnemonic_value(['$P',num2str(i),'B'], fcsheader_main, mnemonic_separator);
    Par(i).Gain  = get_mnemonic_value(['$P',num2str(i),'G'], fcsheader_main, mnemonic_separator);
    Par(i).Amp   = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    
    % LIN/LOG
    % In FCS 3.1, all floating data is treated as LIN rather than LOG for $PiE--so all $PiE are stored as 0,0,
    % so use PiDISPLAY and an assumed decade of 5--not sure what is desired here
    par_exponent_str = get_mnemonic_value(['$P',num2str(i),'E'], fcsheader_main, mnemonic_separator);
    par_exponent = str2num(par_exponent_str); % converts string to matrix to store decade and log values
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
Misc.COMPENSATION_TYPE     = get_mnemonic_value('COMPENSATION_TYPE', fcsheader_main, mnemonic_separator);
Misc.FLOW_MODE             = get_mnemonic_value('FLOW_MODE', fcsheader_main, mnemonic_separator);
Misc.FLOW_VELOCITY         = get_mnemonic_value('FLOW_VELOCITY', fcsheader_main, mnemonic_separator);
Misc.FSC_CHN               = get_mnemonic_value('FSC_CHN', fcsheader_main, mnemonic_separator);
Misc.FSC_COMP_CO           = get_mnemonic_value('FSC_COMP_CO', fcsheader_main, mnemonic_separator);
Misc.FSC_INTENSITY         = get_mnemonic_value('FSC_INTENSITY', fcsheader_main, mnemonic_separator);
Misc.INSPIRE_VERSION       = get_mnemonic_value('INSPIRE_VERSION', fcsheader_main, mnemonic_separator);
Misc.LAST_CALIBRATION_DATE = get_mnemonic_value('LAST_CALIBRATION_DATE', fcsheader_main, mnemonic_separator);
Misc.NUM_LASERS            = get_mnemonic_value('NUM_LASERS', fcsheader_main, mnemonic_separator);
Misc.SAMPLE_TYPE           = get_mnemonic_value('SAMPLE_TYPE', fcsheader_main, mnemonic_separator);
Misc.SSC_CHN               = get_mnemonic_value('SSC_CHN', fcsheader_main, mnemonic_separator);
Misc.SSC_COMP_CO           = get_mnemonic_value('SSC_COMP_CO', fcsheader_main, mnemonic_separator);
Misc.BEGINDATA             = get_mnemonic_value('$BEGINDATA', fcsheader_main, mnemonic_separator);
Misc.ENDDATA               = get_mnemonic_value('$ENDDATA', fcsheader_main, mnemonic_separator);
Misc.BEGINANALYSIS         = get_mnemonic_value('$BEGINANALYSIS', fcsheader_main, mnemonic_separator);
Misc.ENDANALYSIS           = get_mnemonic_value('$ENDANALYSIS', fcsheader_main, mnemonic_separator);
Misc.BEGINTEXT             = get_mnemonic_value('$BEGINSTEXT', fcsheader_main, mnemonic_separator);
Misc.ENDTEXT               = get_mnemonic_value('$ENDSTEXT', fcsheader_main, mnemonic_separator);
Misc.NEXTDATA              = get_mnemonic_value('$NEXTDATA', fcsheader_main, mnemonic_separator);

% % Additional
% % Obtains all data written between '>' and '<'
% expression = '>[\w|]+<';
% name_expression = '<\w+>';
% %fcsheader = char(fcsheader_main');
% [startindexinfo, endindexinfo] = regexp(fcsheader_main, expression); % gets the indexes for all expressions of characters in between > ... <
% [startindexname, endindexname] = regexp(fcsheader_main, name_expression); % gets the indexes for all expressions of characters between < ... >
% if ~isempty(startindexinfo)
%     for i = 1:numel(startindexinfo) % for each time there are characters between > ... <
%         index = find(~(endindexname - startindexinfo(i))); % finds the corresponding name for the data stored in > ... <
%         if ~isempty(index)
%             name = fcsheader_main(startindexname(index) + 1:endindexname(index) - 1);
%             Additional.(name) = fcsheader_main(startindexinfo(i) + 1:endindexinfo(i) - 1); % data associated with the name
%         else % if the data has no associated name, then nothing is recorded and that data is lost
%         end
%     end
% else
%     Additional = []; % returns an empty matrix if no characters found between > ... < at all
% end

% %Obtains all data written between " "--this mostly works with some quirks
% index = strfind(fcsheader_main, '"');
% another_index = strfind(fcsheader_main, '?');
% indexstart = index(1:2:end);
% indexend = index(2:2:end);
% for i = 1:numel(indexstart)
%     try
%         quote_attempt = indexstart(i) - indexend(i - 1);
%     catch
%         quote_attempt = size(fcsheader_main, 2); % ensures it will always be bigger than qmark_attempt
%     end
%     qmark_attempt = another_index - indexstart(i);
%     qmark_attempt_negative = qmark_attempt < 0; % prevents finding ? that are beyond the desired data which owuld give the wrong name
%     qmark_attempt = qmark_attempt_negative .* qmark_attempt;
%     qmark_attempt = min(abs(nonzeros(qmark_attempt)));
%     if quote_attempt < qmark_attempt % if the closest " is closer than the closest ?
%         namestart = indexstart(i) - quote_attempt; % gets closest " and starts to read from there
%     else % ? is closer
%         namestart = indexstart(i) - qmark_attempt; % gets closest ? and starts to read from there
%     end
%     var_name = fcsheader_main(namestart + 1:indexstart(i) - 2);
%     var_name = strtrim(var_name); % eliminates leading and trailing whitespace
%     valid_var_name = matlab.lang.makeValidName(var_name); % makes the name of variable valid
%     Additional.(valid_var_name) = fcsheader_main(indexstart(i) + 1:indexend(i) - 1);
% end

% Lasers
NumOfLasers = 0; % counts how many loops where LaserName is found
i = 1; % used to increment the loop
LaserName = get_mnemonic_value(['LASER',num2str(i),'_MW'], fcsheader_main, mnemonic_separator); % get first value to start loop
while ~isempty(LaserName) % loop only runs if LaserName is found
    LaserName = get_mnemonic_value(['LASER',num2str(i),'_MW'], fcsheader_main, mnemonic_separator);
    if ~isempty(LaserName) % NumofChannels only recorded if LaserName is not empty
        NumOfLasers = NumOfLasers + 1;
    end
    i = i + 1;
end
Laser = struct('MW', cell(1, NumOfLasers), 'WAVELENGTH', cell(1, NumOfLasers), 'ZONE', cell(1, NumOfLasers));
for i = 1:NumOfLasers
    Laser(i).MW         = get_mnemonic_value(['LASER',num2str(i),'_MW'], fcsheader_main, mnemonic_separator);
    Laser(i).WAVELENGTH = get_mnemonic_value(['LASER',num2str(i),'_WAVELENGTH'], fcsheader_main, mnemonic_separator);
    Laser(i).ZONE       = get_mnemonic_value(['LASER',num2str(i),'_ZONE'], fcsheader_main, mnemonic_separator);
end
end

function mneval = get_mnemonic_value(mnemonic_name, fcsheader, mnemonic_separator)
% Adds mnemonic separator to end as mnemonic name can appear more than once
% in fcsheader
mnemonic_separator = double(mnemonic_separator);
mnemonic_name = double(mnemonic_name); % convert to decimals
mnemonic_name = [mnemonic_name mnemonic_separator]; % add mnemonic separator to end which specifies which name
mnemonic_name = char(mnemonic_name); % convert back to characters to search through fcsheader
mnemonic_startpos = strfind(fcsheader, mnemonic_name); % finds the mnemonic name in the fcsheader
if isempty(mnemonic_startpos) % if the mnemonic name is not found, return the null array
    %mneval = [];
    mneval = '';
    return;
else
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_separators = strfind(fcsheader(mnemonic_stoppos:end), char(mnemonic_separator)); % finds all the mnemonic separators in the fcsheader after the mnemonic name
    next_separator = next_separators(1) + mnemonic_stoppos; % the next mnemonic separator
    mneval = fcsheader(mnemonic_stoppos:next_separator - 2);
end
end