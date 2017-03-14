function CNo=findCNo(sampleNum,readyChnList,trackResults,settings)
% Find CNo for at rinex reported receiver time
%
%  CNo=findCNo(sampleNum,trackResults)
%
%   Inputs:
%       sampleNum         - sample number at the time
%       readyChnList      - available channel list
%       trackResults      - Data structure from Tracking
%       settings          - receiver settings.
%   Outputs:
%       CNo               - CNo at the sample number

numOfMeas=length(readyChnList);

% Initialize the transmitting time
CNo=zeros(1,numOfMeas);

% Calcuate the range of the index to accelerate index search
indexEst=round((sampleNum-settings.skipNumberOfSamples)/settings.samplingFreq*1000);

for channelNr = readyChnList
    
    indexRange=indexEst-20:indexEst+20;
    index1=find(trackResults(channelNr).absoluteSample(indexRange)<=sampleNum, 1, 'last' );
    index2=find(trackResults(channelNr).absoluteSample(indexRange)>=sampleNum, 1 );
    
    if index1==index2
        index=index1;
    else
        sampleRange=trackResults(channelNr).absoluteSample(indexRange(index1:index2));
        indexRange=indexRange(index1:index2);
        index=interp1(sampleRange,indexRange,sampleNum);
    end
    
    ind1=find(trackResults(channelNr).CNo.VSMIndex<=index, 1, 'last' );
    ind2=find(trackResults(channelNr).CNo.VSMIndex>=index, 1 );
    
    if isempty(ind2)==1 || ind1==ind2 
        CNo(channelNr)=trackResults(channelNr).CNo.VSMValue(ind1);
    else
        cnoRange=trackResults(channelNr).CNo.VSMValue(ind1:ind2);
        indRange=[trackResults(channelNr).CNo.VSMIndex(ind1),...
            trackResults(channelNr).CNo.VSMIndex(ind2)];
        
        CNo(channelNr)=interp1(indRange,cnoRange,index);
    end
end
    


