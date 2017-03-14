function rinexObsData(fid,rinexData)
% Write rinex obs file
% 
%  rinexObsData(fid,rinexData,weekNumber,PRNlist)
%
%   Inputs:
%       fid               - file ID
%       rinexData         - Rinex data structure



%Limitation - Currently supporting a maximum of 12 channels

PRNlist=rinexData.PRNlist;
for i=1:length(rinexData.rxTime)
    TOW      = rinexData.rxTime(i);
    calcTime    = calcDateTime(rinexData.weekNumber,TOW);
    year        = num2str(calcTime.year);
    year        = year(3:4);
    month       = num2str(calcTime.month);
    day         = num2str(calcTime.day);
    hour        = num2str(calcTime.hour);
    minute      = num2str(calcTime.minute);
    second      = calcTime.second;
    epochFlag   = '0'; %Setting to zero for now
    satCount    = length(PRNlist);
    satCount    = min(satCount,12);% Currently supports only 12 channels
    prnStr      = '';
        
    for j=1:length(PRNlist)
        prn=sprintf('%2s',num2str(rinexData.channel(j).PRN));
        prnStr=[prnStr,'G',prn];
    end
    
    %year,month,day,hour,min,sec,epochFlag,prnCount,prnIds,receiver clock
    %offset(optional)
    outStr = sprintf(' %s %2s %2s %2s %2s%11.7f  %s%3s%-36s\n',...
                            year,month,day,hour,minute,second,epochFlag,num2str(satCount),prnStr);
    fprintf(fid,'%s',outStr);
    
        
    for j=1:length(PRNlist)
        C1 = rinexData.channel(j).pseudorange(i);
        L1 = rinexData.channel(j).carrierPhase(i);
        D1 = rinexData.channel(j).doppler(i);
        S1 = rinexData.channel(j).CNo(i);
        LLI= ' '; %Loss of Lock Indicator
        SS = ' '; %Signal Strength
    
        outStr = sprintf('%14.3f%s%s%14.3f%s%s%14.3f%s%s%14.3f%s%s\n',...
                          C1,LLI,SS,L1,LLI,SS,D1,LLI,SS,S1,LLI,SS);
        fprintf(fid,'%s',outStr);              
                      
    end
    
end;
    

