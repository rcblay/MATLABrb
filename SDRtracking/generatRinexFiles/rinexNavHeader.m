function rinexNavHeader(fid,almanac,settings)
% Write rinex nav file header
%
%  rinexNavHeader(fid)
%
%   Inputs:
%       fid               - file ID
%       almanac           - Iono and UTC parameters
%       settings          - receiver settings.


version = 2.10;
fileType = 'NAV';
space='';

headerLabel = 'RINEX VERSION / TYPE';
headerStr = sprintf('%9.2f%11s%20s%20s%s\n',version,space,fileType,...
                                space,headerLabel);

headerLabel = 'PGM / RUN BY / DATE';
pgm ='GNSS SDR';
runBy = settings.runBy;
date = datestr(now,'dd-mmm-yy HH:MM:SS');
headerStr = sprintf('%s%-20s%-20s%-20s%s\n',headerStr,pgm,runBy,date,headerLabel);

headerLabel = 'ION ALPHA';
a0=adjustFormat(sprintf('%12.3E',almanac.a0),12);
a1=adjustFormat(sprintf('%12.3E',almanac.a1),12);
a2=adjustFormat(sprintf('%12.3E',almanac.a2),12);
a3=adjustFormat(sprintf('%12.3E',almanac.a3),12);
headerStr=sprintf('%s%2s%s%s%s%s%10s%s\n',headerStr,space,a0,a1,a2,a3,space,headerLabel);

headerLabel = 'ION BETA';
B0=adjustFormat(sprintf('%12.3E',almanac.beta0),12);
B1=adjustFormat(sprintf('%12.3E',almanac.beta1),12);
B2=adjustFormat(sprintf('%12.3E',almanac.beta2),12);
B3=adjustFormat(sprintf('%12.3E',almanac.beta3),12);
headerStr=sprintf('%s%2s%s%s%s%s%10s%s\n',headerStr,space,B0,B1,B2,B3,space,headerLabel);

headerLabel = 'DELTA-UTC: A0,A1,T,W';
A0=adjustFormat(sprintf('%19.11E',almanac.A0),19);
A1=adjustFormat(sprintf('%19.11E',almanac.A1),19);
T=almanac.t_ot;
W=almanac.WNt;
headerStr=sprintf('%s%3s%s%s%9d%9d%1s%s\n',headerStr,space,A0,A1,T,W,space,headerLabel);

headerLabel = 'LEAP SECONDS';
leapSec     = almanac.deltaTls;
headerStr=sprintf('%s%6d%54s%s\n',headerStr,leapSec,space,headerLabel);


headerLabel = 'END OF HEADER';
headerStr = sprintf ('%s%60s%s\n',headerStr,space,headerLabel);

fprintf(fid,'%s',headerStr);