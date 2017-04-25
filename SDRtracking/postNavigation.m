function [navSolutions, eph] = postNavigation(trackResults, settings)
%Function calculates navigation solutions for the receiver (pseudoranges,
%positions). At the end it converts coordinates from the WGS84 system to
%the UTM, geocentric or any additional coordinate system.
%
%[navSolutions, eph] = postNavigation(trackResults, settings)
%
%   Inputs:
%       trackResults    - results from the tracking function (structure
%                       array).
%       settings        - receiver settings.
%   Outputs:
%       navSolutions    - contains measured pseudoranges, receiver
%                       clock error, receiver coordinates in several
%                       coordinate systems (at least ECEF and UTM).
%       eph             - received ephemerides of all SV (structure array).

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis with help from Kristin Larson
% Modified By Xiaofan Li at University of Colorado at Boulder
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

%CVS record:
%$Id: postNavigation.m,v 1.1.2.22 2006/08/09 17:20:11 dpl Exp $

%% Phase Lock Detector
for channelNr = 1 : settings.numberOfChannels
    if (trackResults(channelNr).status ~= '-')
        trackResults(channelNr).LockTime =zeros(1,settings.msToProcess);
        for loopCnt=1:settings.msToProcess
            % If I_P is less than threshold, reset lock count
            if abs(trackResults(channelNr).I_P(loopCnt)) < settings.ldConstant*...
                    (trackResults(channelNr).plThreshold(loopCnt)/loopCnt)
                trackResults(channelNr).LockTime(loopCnt) = 0;
                % Otherwise, increase counter
            else
                if loopCnt==1
                    trackResults(channelNr).LockTime(loopCnt)=1;
                else
                    trackResults(channelNr).LockTime(loopCnt) = ...
                        trackResults(channelNr).LockTime(loopCnt-1) + 1;
                end
            end
        end
    end
end

%% Check is there enough data to obtain any navigation solution ===========
% It is necessary to have at least three subframes (number 1, 2 and 3) to
% find satellite coordinates. Then receiver position can be found too.
% The function requires all 5 subframes, because the tracking starts at
% arbitrary point. Therefore the first received subframes can be any three
% from the 5.
% One subframe length is 6 seconds, therefore we need at least 30 sec long
% record (5 * 6 = 30 sec = 30000ms). We add extra seconds for the cases,
% when tracking has started in a middle of a subframe.

if (settings.msToProcess < 36000) || (sum([trackResults.status] ~= '-') < 4)
    % Show the error message and exit
    %disp('Record is to short or too few satellites tracked. Exiting!');
    navSolutions = [];
    eph          = [];
    return
else
    eph            = initEph(settings);
    navBitsSamples = zeros(1,302*20);
end


%% Find preamble start positions ==========================================
[subFrameStart, activeChnList] = findPreambles(trackResults, settings);

%% Decode ephemerides =====================================================
tempList=zeros(1,length(activeChnList));
listNum=1;
for channelNr = activeChnList
    tempList(listNum)=channelNr;
    %=== Convert tracking output to navigation bits =======================
    disp(['   Decoding ephemeris for PRN ',num2str(trackResults(channelNr).PRN)]);
    % find the total number of subframe that could be decoded
    numOfSubFrame=...
        floor((settings.msToProcess-subFrameStart(channelNr)+1)/6000);
    % decode ephemeris subframe by subframe
    for subFrameNo=1:numOfSubFrame
        % Copy 1 sub-frames long record from tracking output
        subFrameRange=subFrameStart(channelNr) +(subFrameNo-1)*6000 - 40:...
            subFrameStart(channelNr) + subFrameNo * 6000 -1;
        navBitsSamples = trackResults(channelNr).I_P(subFrameRange)';
        % Group every 20 vales of bits into columns
        navBitsSamples = reshape(navBitsSamples, ...
            20, (size(navBitsSamples, 1) / 20));
        % Sum all samples in the bits to get the best estimate
        navBits = sum(navBitsSamples);
        % --- Now threshold and make 1 and 0 ------------------------------
        % The expression (navBits > 0) returns an array with elements set 
        % to 1 if the condition is met and set to 0 if it is not met.
        navBits = (navBits > 0);
        %--- Convert from decimal to binary -------------------------------
        navBitsBin = dec2bin(navBits);
        %=== Decode ephemerides for the decoded subframe
        [eph,timeOfSub] = ...
            ephemeris(eph,trackResults(channelNr).PRN,...
            navBitsBin(3:end)',navBitsBin(1),navBitsBin(2));
        if timeOfSub==0
            % Erroneous ephemeris decoded, then exclude this channel 
            disp(['Ephemeris in PRN ',num2str(trackResults(channelNr).PRN),' is not reliable, exclude this PRN']);
            tempList(listNum)=0;
            break;
        end
        % find the TOW for the first decoded subframe
        if subFrameNo==1
            TOW=timeOfSub;
        end
    end
    listNum=listNum+1;
end

activeChnList=tempList(tempList>0);
%% Check if the number of satellites is still above 3 =====================
if (isempty(activeChnList) || (size(activeChnList, 2) < 4))
    % Show error message and exit
    disp('Too few satellites with ephemeris data for postion calculations. Exiting!');
    navSolutions = [];
    return
end

%% Initialization =========================================================
% Set the satellite elevations array to INF to include all satellites for
% the first calculation of receiver position. There is no reference point
% to find the elevation angle as there is no receiver position estimate at
% this point.
satElev  = inf(1, settings.numberOfChannels);

% Save the active channel list. The list contains satellites that are
% tracked and have the required ephemeris data. In the next step the list
% will depend on each satellite's elevation angle, which will change over
% time.
readyChnList = activeChnList;
% Establish the transmitting time table
% Find the last sample number in the tracking results
lastSample=inf(1,max(readyChnList));

for channelNr = readyChnList
    lastSample(channelNr) = ...
        trackResults(channelNr).absoluteSample(settings.msToProcess);
end
% Find the step size for navigation solution
navStep=settings.samplingFreq/settings.navSolRate;

% Find the sample number for the first navigation calculation
firstSample=settings.samplingFreq/settings.navSolRate...
        +settings.skipNumberOfSamples+...
        settings.transition*settings.samplingFreq;

% Initial Estimation of the user position
xyzdt=zeros(1,4);

% Total number of navigation calculation
numOfNav=fix((min(lastSample) -firstSample) /navStep);

%% Check the lock detector in the tracking results
%  if there is a loss of lock detected after the first sample number, then
%  this channel should not be used in the velocity solution
velActChnList=zeros(1,length(readyChnList));
indexStart=round(firstSample/settings.samplingFreq*1000);
for channelNr = 1:length(readyChnList)
    if ~any(trackResults(readyChnList(channelNr)).LockTime(indexStart:end)==0)==1
        velActChnList(channelNr)=readyChnList(channelNr);
    else
        disp(['Loss of lock is found in channel ',num2str(readyChnList(channelNr))]);
    end
end
velActChnList=activeChnList(velActChnList>0);

%##########################################################################
%#   Do the satellite and receiver position and velocity calculations     #
%##########################################################################
%% Initialization of current measurement ==================================
for currMeasNr =1:numOfNav
    % Exclude satellites, that are below elevation mask
    activeChnList = intersect(find(satElev >= settings.elevationMask), ...
        readyChnList);
    if mod(currMeasNr,10)==1
        disp(['   Navigation Calculation No.',num2str(currMeasNr),' Of ',num2str(numOfNav)]);
    end
    
    % Save list of satellites used for position calculation
    navSolutions.channel.PRN(activeChnList, currMeasNr) = ...
        [trackResults(activeChnList).PRN];
    
    % These two lines help the skyPlot function. The satellites excluded
    % do to elevation mask will not "jump" to possition (0,0) in the sky
    % plot.
    navSolutions.channel.el(:, currMeasNr) = ...
        NaN(settings.numberOfChannels, 1);
    navSolutions.channel.az(:, currMeasNr) = ...
        NaN(settings.numberOfChannels, 1);
    
    
    %% Calculate the current sample number, the transmitting time of the
    %  satellite and raw receiver time with or without clock steering
    if currMeasNr <= 2
        sampleNum=firstSample+(currMeasNr-1)*navStep;
        transmitTime=...
            findTransTime(sampleNum,readyChnList,subFrameStart,TOW...
            ,trackResults,settings);
        switch currMeasNr
            case 1
                % Estimate the first receiver time
                rxTime=max(transmitTime)+settings.startOffset/1000;
            case 2
                % Propagate the receiver time by the navSolution rate
                rxTime=rxTime+1/settings.navSolRate;
        end
        navSolutions.samPerSecBuff(currMeasNr)=settings.samplingFreq;
    else
        % The delta corrected receiver time between two adjacent epochs
        deltaTime=diff(navSolutions.rxTime(currMeasNr-2:currMeasNr-1));
        % The delta absolute samples between two adjacent epochs
        deltaSample=diff(navSolutions.absoluteSample(currMeasNr-2:currMeasNr-1));
        % Set the samples per second buffer
        navSolutions.samPerSecBuff(currMeasNr)=deltaSample/deltaTime;
        % Clock steering starts from the third epoch
        if currMeasNr==3
            if settings.clockSteerOn == 1
                % Find the receiver time which is in the multiple of the updated epoch
                rxTime=navSolutions.rxTime(currMeasNr-1)-...
                    mod(navSolutions.rxTime(currMeasNr-1),1/settings.navSolRate)...
                    +1/settings.navSolRate;
            else
                rxTime=rxTime+1/settings.navSolRate;
            end
        else
            rxTime=rxTime+1/settings.navSolRate;
        end
        
        timeUpdate=rxTime-navSolutions.rxTime(currMeasNr-1);
        
        % Find the averaged samples per second
        if currMeasNr <= settings.clkStrAveNum+2
            samplePerSec=navSolutions.samPerSecBuff(currMeasNr);          
        else
            samplePerSec=mean(navSolutions.samPerSecBuff(currMeasNr...
                -settings.clkStrAveNum:currMeasNr-1));
        end
        % Calculate the propagation value for the sample number
        sampleUpdate=samplePerSec*timeUpdate;
        % Propagate the sample number
        if settings.clockSteerOn == 1
            sampleNum=sampleNum+sampleUpdate;
        else
            sampleNum=sampleNum+navStep;
        end
        transmitTime=...
            findTransTime(sampleNum,readyChnList,subFrameStart,TOW...
            ,trackResults,settings);
    end
    
    %% check the health and record number of ephemeris
    % if the satellite is unhealty, then it is removed from the satellite
    % list. Besides, based on the transmit time of the satellites,the 
    % following satellite orbits calculation should use the most recent ephemeris.
    [activeChnList,ephRecNum,navSolutions.channel.el(:, currMeasNr)] =...
        checkEphStatus(eph.nav,transmitTime,activeChnList,...
        navSolutions.channel.PRN(:, currMeasNr),navSolutions.channel.el(:, currMeasNr));
    
    % Find the intersection of the velocity active channel and position
    % active channel
    velChnList=intersect(velActChnList,activeChnList);
    
    %% Interpolate doppler and carrier phase
    [navSolutions.channel.doppler(:, currMeasNr),...
        navSolutions.channel.carrPhase(:, currMeasNr)]=...
    findDopCarrPhase(sampleNum,readyChnList,trackResults,settings);

    %% Interpolate CNo for the time of measurement
    
    navSolutions.channel.CNo(:, currMeasNr)=...
        findCNo(sampleNum,readyChnList,trackResults,settings);
    
    
    %% Find pseudoranges ==================================================
    navSolutions.channel.rawP(:, currMeasNr) = calculatePseudoranges(...
        transmitTime,rxTime,activeChnList,settings);
    
    %% Find satellites positions and clocks corrections ===================
    [satPositions,satVelocity,satClkCorr] = satPosVel(transmitTime, ...
        [trackResults(1:length(transmitTime)).PRN],eph.nav,ephRecNum,activeChnList);
    
    % Record the satellites position velocity and clocks corrections
    navSolutions.channel.satPositions(:,activeChnList,currMeasNr) = satPositions(:,activeChnList);
    navSolutions.channel.satVelocity(:,activeChnList,currMeasNr)  = satVelocity(:,activeChnList);
    navSolutions.channel.satClkCorr(activeChnList,currMeasNr)     = satClkCorr(activeChnList);
    
    % Determine the actual satellite transmitted frequency and measured
    % estimate of the received signal frequency
    for channelNr=activeChnList
        prnNum=trackResults(channelNr).PRN;
        af1=eph.nav(ephRecNum(channelNr),prnNum).a_f1;
        navSolutions.channel.transmitFreq(channelNr,currMeasNr)...
            =settings.L1Freq *(1+af1);
        navSolutions.channel.receivedFreq(channelNr,currMeasNr)...
            =settings.L1Freq +navSolutions.channel.doppler(channelNr, currMeasNr);
    end
         
    %% Find receiver position and velocity=====================================
    
    % 3D receiver position can be found only if signals from more than 3
    % satellites are available
    if size(activeChnList, 2) > 3
        
        %=== Calculate receiver position ==================================
        [xyzdt, ...
            navSolutions.channel.el(activeChnList, currMeasNr), ...
            navSolutions.channel.az(activeChnList, currMeasNr), ...
            navSolutions.channel.iono(activeChnList, currMeasNr),...
            navSolutions.channel.tropo(activeChnList, currMeasNr),...
            navSolutions.DOP(:, currMeasNr)] = leastSquarePos(satPositions(:,activeChnList), ...
            navSolutions.channel.rawP(activeChnList, currMeasNr)' ...
            + satClkCorr(activeChnList) * settings.c,xyzdt,...
            eph.almanac,rxTime,settings);
        
        
        %--- Save pos results ---------------------------------------------
        navSolutions.X(currMeasNr)  = xyzdt(1);
        navSolutions.Y(currMeasNr)  = xyzdt(2);
        navSolutions.Z(currMeasNr)  = xyzdt(3);
        navSolutions.dt(currMeasNr) = xyzdt(4);
        
        % Update the satellites elevations vector
        satElev = navSolutions.channel.el(:, currMeasNr);
        
        % Compute the corrected receiver time
        navSolutions.rxTime(currMeasNr)=rxTime-...
            navSolutions.dt(currMeasNr)/settings.c;
        % Record the sample number and raw receiver time
        navSolutions.absoluteSample(currMeasNr) =sampleNum;
        navSolutions.rawRxTime(currMeasNr)=rxTime;
        
        % 3D velocity can be found only if there are more than three
        % channels avaiable for velocity calculation
        if size(velChnList, 2) > 3
            %=== Calculate receiver velocity ==================================
            switch settings.velSol
                %%Velocity Solution Method 1
                case 1
                    if currMeasNr==1
                        velXYZdtRate =...
                            leastSquareVel2(navSolutions.channel.transmitFreq(:,currMeasNr)...
                            ,navSolutions.channel.receivedFreq(:,currMeasNr),satPositions...
                            ,satVelocity,xyzdt(1:3)',velChnList,settings);
                    else
                        % The delta corrected receiver time between two adjacent epochs
                        deltaTime=diff(navSolutions.rxTime(currMeasNr-1:currMeasNr));
                        % Find the differential carrier phase between two adjacent
                        % epochs
                        carrPhaseDiff =(navSolutions.channel.carrPhase(velChnList, currMeasNr)...
                            -navSolutions.channel.carrPhase(velChnList, currMeasNr-1))*settings.c/settings.L1Freq;
                        % Find the change rate of the carrier phase measurement
                        carrPhaseDiff = carrPhaseDiff./deltaTime;
                        % Record the delta errrors (satellite clock drift)
                        deltaErrors =(navSolutions.channel.satClkCorr(velChnList,currMeasNr)-...
                            navSolutions.channel.satClkCorr(velChnList,currMeasNr-1))*settings.c;
                        % Find the error rate
                        deltaErrors=deltaErrors./deltaTime;
                        % Calculate the compensated SD carrier phase
                        cpCompDiff=carrPhaseDiff+deltaErrors;
                        % Calculate the differential tropo error
                        deltaTropo=...
                            diff(navSolutions.channel.tropo(velChnList,currMeasNr-1:currMeasNr),1,2);
                        % Find the tropo change rate
                        deltaTropo=deltaTropo./deltaTime;
                        % Calculate the differential iono error
                        deltaIono=...
                            diff(navSolutions.channel.iono(velChnList,currMeasNr-1:currMeasNr),1,2);
                        % Find the iono change rate
                        deltaIono=deltaIono./deltaTime;
                        % Correct the iono and tropo change rate from the
                        % differential carrier phase
                        cpCompDiff=cpCompDiff-deltaTropo+deltaIono;
                        
                        velXYZdtRate = leastSquareVel1(currMeasNr,navSolutions,...
                            cpCompDiff,velChnList);
                    end
                    
                    %% Velocity Solution Method 2
                case 2
                    velXYZdtRate =...
                        leastSquareVel2(navSolutions.channel.transmitFreq(:,currMeasNr)...
                        ,navSolutions.channel.receivedFreq(:,currMeasNr),satPositions...
                        ,satVelocity,xyzdt(1:3)',velChnList,settings);
                otherwise
                    disp('Error: settings.velSol should be either 1 or 2');
                    return;
                    
            end
            
            navSolutions.VX(currMeasNr)=velXYZdtRate(1);
            navSolutions.VY(currMeasNr)=velXYZdtRate(2);
            navSolutions.VZ(currMeasNr)=velXYZdtRate(3);
            navSolutions.dtRate(currMeasNr)=velXYZdtRate(4);
        else
            %--- There are not enough satellites to find 3D velocity ----------
            if mod(currMeasNr,10)==1
                disp(['   Measurement No. ', num2str(currMeasNr), ...
                    ': Not enough information for velocity solution.']);
            end
            navSolutions.VX(currMeasNr)=0;
            navSolutions.VY(currMeasNr)=0;
            navSolutions.VZ(currMeasNr)=0;
            navSolutions.dtRate(currMeasNr)=0;
        end
        
        % correct the doppler from receiver clock drift
        navSolutions.channel.correctedDop(:, currMeasNr)=...
            navSolutions.channel.receivedFreq(:,currMeasNr)*...
            (1+navSolutions.dtRate(currMeasNr)/settings.c)...
            -navSolutions.channel.transmitFreq(:,currMeasNr);
           
        %=== Correct pseudorange measurements for receiver clocks errors ==
        navSolutions.channel.correctedP(activeChnList, currMeasNr) = ...
            navSolutions.channel.rawP(activeChnList, currMeasNr) -...
            navSolutions.dt(currMeasNr);
        
        %=== Calculate the geometric ranges for each channel ==============
        navSolutions.channel.geoRange(activeChnList, currMeasNr) = ...
            navSolutions.channel.rawP(activeChnList, currMeasNr) + ...
            satClkCorr(activeChnList)' * settings.c - navSolutions.dt(currMeasNr);
        
        %% Coordinate conversion ==================================================
        
        %=== Convert to geodetic coordinates ==============================
        [navSolutions.latitude(currMeasNr), ...
            navSolutions.longitude(currMeasNr), ...
            navSolutions.height(currMeasNr)] = cart2geo(...
            navSolutions.X(currMeasNr), ...
            navSolutions.Y(currMeasNr), ...
            navSolutions.Z(currMeasNr), ...
            5);
        
        %=== Convert to UTM coordinate system =============================
        navSolutions.utmZone = findUtmZone(navSolutions.latitude(currMeasNr), ...
            navSolutions.longitude(currMeasNr));
        
        [navSolutions.E(currMeasNr), ...
            navSolutions.N(currMeasNr), ...
            navSolutions.U(currMeasNr)] = cart2utm(xyzdt(1), xyzdt(2), ...
            xyzdt(3), ...
            navSolutions.utmZone);
        
        %DMA add - get the precise time of the first sample and the avg
        %clock rate for the file (skip first 5 samples and should be
        %enough to get over transients)
        if (currMeasNr == fix((min(lastSample) - firstSample) /navStep))
            dmaTime=polyfit(navSolutions.absoluteSample(5:end)-settings.skipNumberOfSamples,navSolutions.rxTime(5:end),1);
            navSolutions.avgClock = 1/dmaTime(1);
            navSolutions.firstSampleTime = 1 * dmaTime(1) + dmaTime(2);
        end
    else % if size(activeChnList, 2) > 3
        %--- There are not enough satellites to find 3D position ----------
        disp(['   Measurement No. ', num2str(currMeasNr), ...
            ': Not enough information for position solution.']);

        %--- Set the missing solutions to NaN. These results will be
        %excluded automatically in all plots. For DOP it is easier to use
        %zeros. NaN values might need to be excluded from results in some
        %of further processing to obtain correct results.
        navSolutions.X(currMeasNr)           = NaN;
        navSolutions.Y(currMeasNr)           = NaN;
        navSolutions.Z(currMeasNr)           = NaN;
        navSolutions.dt(currMeasNr)          = NaN;
        navSolutions.DOP(:, currMeasNr)      = zeros(5, 1);
        navSolutions.latitude(currMeasNr)    = NaN;
        navSolutions.longitude(currMeasNr)   = NaN;
        navSolutions.height(currMeasNr)      = NaN;
        navSolutions.E(currMeasNr)           = NaN;
        navSolutions.N(currMeasNr)           = NaN;
        navSolutions.U(currMeasNr)           = NaN;
        navSolutions.rawRxTime(currMeasNr)         = NaN;
        navSolutions.absoluteSample(currMeasNr)    = NaN;
        navSolutions.rxTime(currMeasNr)            = NaN;
        
        navSolutions.channel.az(activeChnList, currMeasNr) = ...
            NaN(1, length(activeChnList));
        navSolutions.channel.el(activeChnList, currMeasNr) = ...
            NaN(1, length(activeChnList));
        
        disp('   Exit Program');
        return;
        
        % TODO: Know issue. Satellite positions are not updated if the
        % satellites are excluded do to elevation mask. Therefore rasing
        % satellites will be not included even if they will be above
        % elevation mask at some point. This would be a good place to
        % update positions of the excluded satellites.

    end % if size(activeChnList, 2) > 3
end

% % Adjust the value of carrier phase measurements and make the first
% % pseudorange and carrier phase measurements identical.
navSolutions=corrCarrPhase(navSolutions,settings);
% Record GPS week in the navSolutions
navSolutions.weekNumber=...
    eph.nav(ephRecNum(activeChnList(1)),navSolutions.channel.PRN(activeChnList(1), 1)).weekNumber;
% Convert the GPS time for the first sample to UTC time
if eph.almanac.A0==0
    timeUTC = navSolutions.firstSampleTime-settings.leapSec;
else
    timeUTC = ...
        calUTC(eph.almanac,navSolutions.firstSampleTime,navSolutions.weekNumber);
end
navSolutions.firstSampleTimeUTC = calcDateTime(navSolutions.weekNumber,timeUTC);
% record the satellites used for velocity solution
navSolutions.velSolPRNlist=navSolutions.channel.PRN(velChnList,1)';
% record the satellites used for position solution
navSolutions.posSolPRNlist=navSolutions.channel.PRN(activeChnList,1)';
% record the leap seconds between GPS time and UTC time
t = calcDateTime(navSolutions.weekNumber,navSolutions.firstSampleTime);
navSolutions.leapSec=round(abs(t.second-navSolutions.firstSampleTimeUTC.second));
     

