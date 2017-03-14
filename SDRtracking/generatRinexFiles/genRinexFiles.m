function genRinexFiles(rinexData,settings)
% Generate Rinex files
%
%  genRinexFiles(rinexData,navSolutions,eph)
%
%   Inputs:
%       rinexData         - Rinex data structure
%       settings          - receiver settings.

stationName = settings.stationName;
weekNumber  = rinexData.weekNumber;
TOW         = rinexData.firstRxtime;
calcTime    = calcDateTime(weekNumber,TOW);
year        = num2str(calcTime.year);
year        = year(3:4);
dayofYear   = calcTime.dayofYear;


%% Navigation file
fileNo      = 1;
fileType    = settings.NAV;
fileNameNav = [stationName,num2str(dayofYear),num2str(fileNo),'.',num2str(year),fileType];
fidNav=fopen(fileNameNav,'wt');
% write header for navigation file
rinexNavHeader(fidNav,rinexData.almanac,settings);
% write data for navigation file
rinexNavData(fidNav,rinexData);
fclose(fidNav);


%% Observation File
fileType    = settings.OBS;
fileNo      = 1;
while(fileNo<10)
    
fileNameObs = [stationName,num2str(dayofYear),num2str(fileNo),'.',num2str(year),fileType];

    if (exist(fileNameObs,'file')==2)
        fileNo=fileNo+1;
    else
        fidObs=fopen(fileNameObs,'wt');
        break;
    end
end

if (fileNo >= 10)
    fprintf('%s\n%s\n','File No. Limit Exceeded...', 'Please delete the existing RINEX Files...');
    return
end

% write header for observation file
rinexObsHeader(fidObs,rinexData,settings);
% write data for observation file
rinexObsData(fidObs,rinexData);
fclose(fidObs);