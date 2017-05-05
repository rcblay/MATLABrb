function navSolutions=corrCarrPhase(navSolutions,settings)
%Function adjust and correct carrier phase measurements for each satellite
%
%
% navSolutions=corrCarrPhase(navSolutions,settings)
%
%   Inputs:
%       navSolutions    - contains measured pseudoranges, receiver
%                       clock error, receiver coordinates in several
%                       coordinate systems (at least ECEF and UTM).
%       settings        - receiver settings.
%   Outputs:
%       navSolutions.channel.rawCarrPhase    - raw carrier phase
%       measurement with the first value identical with the first raw
%       pseudorange measurement
%      
%       navSolutions.channel.correctedCP     - corrected carrier phase 
%       (no clock drift is remaining in the carrier phase)
%
numOfSat=size(navSolutions.channel.PRN,1);
numOfEpoch=size(navSolutions.channel.PRN,2);

% If there is no clock steering
if settings.clockSteerOn==0
    
    %% Adjust the raw carrier phase based on raw pseudorange
    %  Rinex file type 1 contains raw carrier phase, raw pseudorange and raw
    %  receiver time (not at integer second)
    firstRawCarrPhase=navSolutions.channel.rawP(1:numOfSat,1)/settings.c*settings.L1Freq;
    diffCarrPhase=zeros(numOfSat,numOfEpoch);
    % Assign the first raw carrier phase to be as same as the first raw pseudorange
    diffCarrPhase(1:numOfSat,1)=firstRawCarrPhase;
    % Find the differntial value of the raw carrier phase
    diffCarrPhase(1:numOfSat,2:end)=diff(navSolutions.channel.carrPhase(1:numOfSat,:),1,2);
    % Accumulate to get the raw carrier phase measurement
    navSolutions.channel.rawCarrPhase=cumsum(diffCarrPhase,2);
    
    %% Adjust the corrrected carrier phase based on the corrected pseudorange
    %  Rinex file type 2 contains corrected carrier phase, corrected
    %  pseudorange and corrected receiver time (not at integer second)
    firstCorrectedCP=navSolutions.channel.correctedP(1:numOfSat,1)/settings.c*1575.42e6;
    diffCarrPhase=zeros(numOfSat,numOfEpoch);
    %  Find the differential corrected receiver time
    diffRxTime(2:numOfEpoch)=diff(navSolutions.rxTime);
    % Assign the first corrected carrier phase to be as same as the first corrected pseudorange
    diffCarrPhase(1:numOfSat,1)=firstCorrectedCP;
    % Find the differntial value of the corrected carrier phase
    diffCarrPhase(1:numOfSat,2:end)=diff(navSolutions.channel.carrPhase(1:numOfSat,:),1,2);
    % Correct the differential carrier phase by dt-rate
    for ii=1:numOfSat
        diffCarrPhase(ii,2:end)=diffCarrPhase(ii,2:end)-...
            navSolutions.dtRate(2:end).*diffRxTime(2:end)*1575.42e6/settings.c;
    end
    % Accumulate to get the corrected carrier phase measurement
    navSolutions.channel.correctedCP=cumsum(diffCarrPhase,2);

% If there is clock steering
else
    %% Adjust the corrected carrier phase based on the raw pseudorange
    %  Rinex file type 3 contains corrected carrier phase, raw pseudorange
    %  and raw receiver time (at integer second, dt and dtRate have been removed)
    %  Measurement starts from the third epoch
    firstRawCarrPhase=navSolutions.channel.rawP(1:numOfSat,3)/settings.c*settings.L1Freq;
    diffCarrPhase=zeros(numOfSat,numOfEpoch);
    % Assign the third raw carrier phase to be as same as the first raw pseudorange
    diffCarrPhase(1:numOfSat,3)=firstRawCarrPhase;
    % Find the differntial value of the raw carrier phase
    diffCarrPhase(1:numOfSat,4:end)=diff(navSolutions.channel.carrPhase(1:numOfSat,3:end),1,2);
    %  Find the differential corrected receiver time
    diffRxTime(4:numOfEpoch)=diff(navSolutions.rawRxTime(3:end));
    % Correct the differential carrier phase by dt-rate
    for ii=1:numOfSat
        diffCarrPhase(ii,4:end)=diffCarrPhase(ii,4:end)-...
            navSolutions.dtRate(4:end).*diffRxTime(4:end)*1575.42e6/settings.c;
    end
    % Accumulate to get the corrected carrier phase measurement
    navSolutions.channel.correctedCP=cumsum(diffCarrPhase,2);
      
end


