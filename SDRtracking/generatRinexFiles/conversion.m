function rinexData=conversion(navSolutions,eph,settings)
% Construct the rinex data structure
% Currently only the satellite that is visible for the whole period will be
% wrote into the rinex file
%
% rinexData=conversion(navSolutions,trackResults)
%
%   Inputs:
%       navSolutions      - Data structure from navSolution
%       eph               - received ephemerides of all SV (structure array).
%       settings          - receiver settings.
%   Outputs:
%       rinexData         - Rinex data structure

% Get the PRNlist for writting the rinex file
PRNlist= navSolutions.channel.PRN(:,end)';
PRNlist=PRNlist(PRNlist>0);

if settings.clockSteerOn==0
    % Without clock steering
    numOfMeas=size(navSolutions.rxTime,2);
    validRange=1:numOfMeas;
    if settings.rinexType==1
        firstRxtime=navSolutions.rawRxTime(1);
        lastRxtime =navSolutions.rawRxTime(end);
        rinexData.rxTime(validRange)=navSolutions.rawRxTime(validRange);
    else
        firstRxtime=navSolutions.rxTime(1);
        lastRxtime =navSolutions.rxTime(end);
        rinexData.rxTime(validRange)=navSolutions.rxTime(validRange);
    end
else
    % With clock steering,starts from the third epoch
    numOfMeas=size(navSolutions.rxTime,2)-2;
    validRange=1:numOfMeas;
    firstRxtime=navSolutions.rawRxTime(3);
    lastRxtime =navSolutions.rawRxTime(end);
    rinexData.rxTime(validRange)=navSolutions.rawRxTime(validRange+2);
end

% Measurement in the rinex file
rinexData.channel.pseudorange=zeros(1,numOfMeas);
rinexData.channel.carrierPhase=zeros(1,numOfMeas);
rinexData.channel.doppler=zeros(1,numOfMeas);
rinexData.channel.CNo=zeros(1,numOfMeas);
rinexData.channel.PRN=0;
rinexData.channel= repmat(rinexData.channel, 1, size(PRNlist,2));

rinexData.firstRxtime=firstRxtime;
rinexData.lastRxtime=lastRxtime;
% PRN List
rinexData.PRNlist=PRNlist;
% GPS week number
rinexData.weekNumber=navSolutions.weekNumber;
% Almanac
rinexData.almanac=eph.almanac;
% Reference ECEF Coordinates
rinexData.X=mean(navSolutions.X);
rinexData.Y=mean(navSolutions.Y);
rinexData.Z=mean(navSolutions.Z);


for ii=1:size(PRNlist,2)
    % For each channel
    PRN=PRNlist(ii);
    rinexData.channel(ii).PRN=PRN;
    rinexData.channel(ii).eph=eph.nav(:,PRN);
    index=find(navSolutions.channel.PRN(:,1)==PRN);
    
    % If there is no clock steering
    if settings.clockSteerOn==0
        switch settings.rinexType
            case 1
                % raw measurements (clock bias and drift remain in the measurements)
                rinexData.channel(ii).pseudorange(validRange)=...
                    navSolutions.channel.rawP(index,validRange);
                rinexData.channel(ii).carrierPhase(validRange)=...
                    navSolutions.channel.rawCarrPhase(index,validRange);
                rinexData.channel(ii).doppler(validRange)=...
                    navSolutions.channel.doppler(index,validRange);
            case 2
                % corrected measurement(clock bias and drift removed)
                rinexData.channel(ii).pseudorange(validRange)=...
                    navSolutions.channel.correctedP(index,validRange);
                rinexData.channel(ii).carrierPhase(validRange)=...
                    navSolutions.channel.correctedCP(index,validRange);
                rinexData.channel(ii).doppler(validRange)=...
                    navSolutions.channel.correctedDop(index,validRange);
            otherwise
                disp(' Error : settings.rinexType should be either 1 or 2');
                return;
        end
        rinexData.channel(ii).CNo(validRange)=...
                    navSolutions.channel.CNo(index,validRange);
    % If there is clock steering
    else
        rinexData.channel(ii).pseudorange(validRange)=...
            navSolutions.channel.rawP(index,validRange+2);
        rinexData.channel(ii).carrierPhase(validRange)=...
            navSolutions.channel.correctedCP(index,validRange+2);
        rinexData.channel(ii).doppler(validRange)=...
            navSolutions.channel.correctedDop(index,validRange+2);
        rinexData.channel(ii).CNo(validRange)=...
            navSolutions.channel.CNo(index,validRange+2);
    end % if settings.clockSteerOn==0
    
end % for ii=1:size(PRNlist,2)



