function transmitTime=...
    findTransTime(sampleNum,readyChnList,subFrameStart,TOW,trackResults,settings)
% findTransTime finds the transmitting time of each satellite at a specified
% sample number using the interpolation
% function transmitTime=...
%     findTransTime(sampleNum,readyChnList,subFrameStart,TOW,trackResults,settings)
%   Inputs:
%       sampleNum     - absolute sample number from the tracking loop
%       readyChnList  - a list of satellites ready for nav solution
%       svTimeTable   - the transmitting time table
%       trackResults  - output from the tracking function
%
%   Outputs:
%       transmitTime  - transmitting time all ready satellites
%--------------------------------------------------------------------------
% Copyright (C) D.M.Akos
% Written by Xiaofan Li at University of Colorado at Boulder
%--------------------------------------------------------------------------
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

% Initialize the transmitting time
transmitTime=zeros(1,length(readyChnList));
% Calcuate the range of the index to accelerate index search
indexEst=round((sampleNum-settings.skipNumberOfSamples)/settings.samplingFreq*1000);
indexRange=indexEst-20:indexEst+20;

% Calculate the transmitting time of each satellite using interpolations
for channelNr = readyChnList
    % Find the index of the sampleNum in the tracking results
    index_a=find(trackResults(channelNr).absoluteSample(indexRange)<=sampleNum, 1, 'last' );
    index_b=find(trackResults(channelNr).absoluteSample(indexRange)>=sampleNum, 1 );
    if index_a~=index_b
        x1=trackResults(channelNr).absoluteSample(indexRange(index_a:index_b));
        y1=indexRange(index_a:index_b);
        index_c=interp1(x1,y1,sampleNum);
        x2=indexRange(index_a:index_b);
        y2=TOW-subFrameStart(channelNr)*0.001+x2*0.001;
        % Find the transmitting time based on the index calculated
        transmitTime(channelNr)=interp1(x2,y2,index_c);
    else
        transmitTime(channelNr)=...
            TOW-subFrameStart(channelNr)*0.001+indexRange(index_a)*0.001;
    end
end