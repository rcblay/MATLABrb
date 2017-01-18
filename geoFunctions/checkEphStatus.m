function [activeChnList,ephRecNum,satElev] =...
    checkEphStatus(eph,transmitTime,channelList,PRNlist,satElev)
% Check the status of ephemeris (update status and health status)
%
% [activeChnList,ephRecNum,satElev] =...
%      checkEphStatus(eph,transmitTime,channelList,PRNlist,satElev)
%
%   Inputs:
%       eph               - ephemeris data
%       transmitTime      - time of transmission for each satellite
%       channelList       - list of ready channels
%       PRNlist           - PRN list
%       satElev           - satellite elevation
%   Outputs:
%       activeChnList     - list of available channels
%       ephRecNum         - number of ephemeris record (update status)
%       satElev           - satellite elevation angle (degrees)

numOfEphRec=size(eph,1);
toe=zeros(1,numOfEphRec);
ephRecNum=zeros(1,max(channelList));
activeChnList=zeros(1,max(channelList));

for channelNr=1:length(channelList)
    
    PRN=PRNlist(channelNr);
    for ii=1:numOfEphRec
        toe(ii)=eph(ii,PRN).t_oe;
    end
    % find the latest updated ephemeris based on the time of ephemeris
    [temp,ephRecNum(channelNr)]=min(abs(transmitTime(channelNr)-toe));
    
    % check the health status of the ephemeris
    %     if eph(ephRecNum(channelNr),PRN).IODC ==0 || ...
    %             eph(ephRecNum(channelNr),PRN).IODE_sf2==0 || ...
    %             eph(ephRecNum(channelNr),PRN).IODE_sf3==0 || ...
    %             eph(ephRecNum(channelNr),PRN).accuracy >=3 ||...
    %             eph(ephRecNum(channelNr),PRN).health~=0
    % For simulator data
    if eph(ephRecNum(channelNr),PRN).t_oc ==0 || ...
            eph(ephRecNum(channelNr),PRN).t_oe ==0 || ...
            eph(ephRecNum(channelNr),PRN).i_0 ==0 || ...
            eph(ephRecNum(channelNr),PRN).accuracy >=3 ||...
            eph(ephRecNum(channelNr),PRN).health~=0
%         if ephRecNum(channelNr)==1
%             satElev(channelNr)=Inf;
%         else
%             % Use the last ephemeris record
%             ephRecNum(channelNr)=ephRecNum(channelNr)-1;
%             activeChnList(channelNr)=channelNr;
%         end
           satElev(channelNr)=Inf;
       
    else
        %activeChnList(channelNr)=channelList(channelNr);
        activeChnList(channelNr)=channelNr;
        
    end
end

activeChnList=activeChnList(activeChnList>0);