function rinexObsHeader(fid,rinexData,settings)
% Write rinex obs file header
%
%  rinexObsHeader(fid,navSolutions,weekNumber,rinexData)
%
%   Inputs:
%       fid               - file ID
%       rinexData         - Rinex data structure
%       settings          - receiver settings.



version = 2.10;
fileType = 'O';
satSystem = 'G';%GPS Only for now
space='';
unknown='|Unknown|';
zero = 0;
headerLabel = 'RINEX VERSION / TYPE';
headerStr = sprintf('%9.2f%11s%s%19s%s%19s%s\n',version,space,fileType,...
                                        space,satSystem,space,headerLabel);
headerLabel = 'PGM / RUN BY / DATE';
pgm ='GNSS SDR';
runBy = settings.runBy;
date = datestr(now,'dd-mmm-yy HH:MM:SS');
headerStr = sprintf('%s%-20s%-20s%-20s%s\n',headerStr,pgm,runBy,date,headerLabel);

headerLabel = 'MARKER NAME';
headerStr = sprintf('%s%-60s%s\n',headerStr,unknown,headerLabel);

headerLabel = 'MARKER NUMBER';
headerStr = sprintf('%s%-60s%s\n',headerStr,unknown,headerLabel);

headerLabel = 'OBSERVER / AGENCY' ;
headerStr = sprintf('%s%-20s%-40s%s\n',headerStr,unknown,unknown,headerLabel);


headerLabel = 'REC # / TYPE / VERS';
headerStr = sprintf('%s%-20s%-20s%-20s%s\n',headerStr,unknown,unknown,unknown,headerLabel);

headerLabel = 'ANT # / TYPE';
headerStr = sprintf('%s%-20s%-20s%-20s%s\n',headerStr,unknown,unknown,space,headerLabel);

headerLabel = 'APPROX POSITION XYZ';
headerStr = sprintf('%s%14.4f%14.4f%14.4f%18s%s\n',headerStr,rinexData.X,...
                        rinexData.Y,rinexData.Z,space,headerLabel);
%CHECK IF WE NEED TO USE NAV SOLUTIONS 

headerLabel = 'ANTENNA: DELTA H/E/N';
headerStr = sprintf('%s%14.4f%14.4f%14.4f%18s%s\n',headerStr,zero,zero,zero,space,headerLabel);

headerLabel = 'WAVELENGTH FACT L1/2';
L1=1;
L2=0;
headerStr = sprintf('%s%6d%6d%6s%42s%s\n',headerStr,L1,L2,space,space,headerLabel);

%Skipping the optional second 'WAVELENGTH FACT L1/2'element

headerLabel = '# / TYPES OF OBSERV';
obsNumber   = 4 ;  %Hardcoding the values for now
obsStr      = '    C1    L1    D1    S1';
headerStr = sprintf('%s%6d%s%30s%s\n',headerStr,obsNumber,obsStr,space,headerLabel);

headerLabel = 'INTERVAL';
obsDataPeriod= 1/settings.navSolRate;
headerStr = sprintf('%s%10.3f%50s%s\n',headerStr,obsDataPeriod,space,headerLabel);

headerLabel = 'TIME OF FIRST OBS';

TOW         = rinexData.firstRxtime;
calcTime    = calcDateTime(rinexData.weekNumber,TOW);
year        = num2str(calcTime.year);
month       = num2str(calcTime.month);
day         = num2str(calcTime.day);
hour        = num2str(calcTime.hour);
minute      = num2str(calcTime.minute);
second      = calcTime.second;
timeSystem  = 'GPS';
headerStr = sprintf('%s%6s%6s%6s%6s%6s%13.7f%5s%3s%9s%s\n',headerStr,year,month,day,hour,...
                    minute,second,space,timeSystem,space,headerLabel); 

headerLabel = 'TIME OF LAST OBS';        
TOW         = rinexData.lastRxtime;
calcTime    = calcDateTime(rinexData.weekNumber,TOW);
year        = num2str(calcTime.year);
month       = num2str(calcTime.month);
day         = num2str(calcTime.day);
hour        = num2str(calcTime.hour);
minute      = num2str(calcTime.minute);
second      = calcTime.second;
headerStr = sprintf('%s%6s%6s%6s%6s%6s%13.7f%5s%3s%9s%s\n',headerStr,year,month,day,hour,...
                    minute,second,space,timeSystem,space,headerLabel); 
%Skipping the following optional headers
% TIME OF LAST OBS 
% RCV CLOCK OFFS APPL
% LEAP SECONDS  
% # OF SATELLITES 
% PRN / # OF OBS  


headerLabel = 'END OF HEADER';
headerStr = sprintf ('%s%60s%s\n',headerStr,space,headerLabel);

fprintf(fid,'%s',headerStr);