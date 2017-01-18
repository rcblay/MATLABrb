function [doppler,carrPhase]=...
    findDopCarrPhase(sampleNum,readyChnList,trackResults,settings)

% Interpolate doppler and carrier phase measurements
%
% [doppler,carrPhase]=...
%     findDopCarrPhase(sampleNum,readyChnList,trackResults,settings)
%
%   Inputs:
%       sampleNum         - sample number at the time
%       readyChnList      - available channel list
%       trackResults      - Data structure from Tracking
%       settings          - receiver settings.
%   Outputs:
%       doppler           - doppler frequency at the sample number
%       carrPhase         - carrier phase measurement at the sample number



numOfChan=length(readyChnList);

% Initialize the transmitting time
doppler=zeros(1,numOfChan);
carrPhase=zeros(1,numOfChan);

% Calcuate the range of the index to accelerate index search
indexEst=round((sampleNum-settings.skipNumberOfSamples)/settings.samplingFreq*1000);
indexRange=indexEst-20:indexEst+20;

% Calculate the doppler and carrier phase each satellite using interpolations
for channelNr = readyChnList
    % Find the index of the sampleNum in the tracking results
    index_a=find(trackResults(channelNr).absoluteSample(indexRange)<=sampleNum, 1, 'last' );
    index_b=find(trackResults(channelNr).absoluteSample(indexRange)>=sampleNum, 1 );
    if index_a~=index_b
        x1=trackResults(channelNr).absoluteSample(indexRange(index_a:index_b));
        y1=indexRange(index_a:index_b);
        index_c=interp1(x1,y1,sampleNum);
        x2=indexRange(index_a:index_b);
        y2=trackResults(channelNr).rawDoppler(x2);
        % Find the doppler based on the index calculated
        doppler(channelNr)=interp1(x2,y2,index_c);
        % Find the carrier phase based on the index calculated
        y2=trackResults(channelNr).rawCarrPhase(x2);
        carrPhase(channelNr)=interp1(x2,y2,index_c);
    else
        doppler(channelNr)=trackResults(channelNr).rawDoppler(indexRange(index_a));
        carrPhase(channelNr)=trackResults(channelNr).rawCarrPhase(indexRange(index_a));
    end
end