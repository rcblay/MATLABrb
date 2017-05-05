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
%
% GLONASS modification by Jakob Almqvist
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


%% Check is there enough data to obtain any navigation solution ===========
% It is necessary to have at least three strings (number 1, 2 and 3) to
% find satellite coordinates. Then receiver position can be found too.
% The function requires all 15 strings, because the tracking starts at
% arbitrary point. Therefore the first received strings can be any three
% from the 5.
% One string length is 2 seconds, therefore we need at least 30 sec long
% record (15 * 2 = 30 sec = 30000ms). We add extra seconds for the cases,
% when tracking has started in a middle of a string.

if (settings.msToProcess < 32000) || (sum([trackResults.status] ~= '-') < 4)
    % Show the error message and exit
    disp('Record is to short or too few satellites tracked. Exiting!');
    navSolutions = [];
    eph          = [];
    return
end

%% Find preamble start positions ==========================================

[subFrameStart, activeChnList] = findPreambles(trackResults, settings);

%% Decode ephemerides =====================================================

for channelNr = activeChnList

    %=== Convert tracking output to navigation bits =======================

    %--- Copy 15 strings long record from tracking output ------------------
    % Skip the time marks.
    clear navBiBinaryBitsSamples  
    for stringIndex = 1:15
          
        navBiBinaryBitsSamples((stringIndex-1)*1700 + 1: stringIndex*1700,1) = ...
           trackResults(channelNr).I_P(subFrameStart(channelNr) + ...
           (stringIndex-1)*2000 : ...
           subFrameStart(channelNr) + (stringIndex-1)*2000 + (170 * 10 ) -1)';
    end

    %--- Group every 10 vales of bits into columns ------------------------
    navBiBinaryBitsSamples = reshape(navBiBinaryBitsSamples, ...
                             10, (size(navBiBinaryBitsSamples, 1) / 10));

    %--- Sum all samples in the bits to get the best estimate -------------
    navBiBinaryBits = sum(navBiBinaryBitsSamples);

    %--- Now threshold and make 1 and 0 -----------------------------------
    % The expression (navBits > 0) returns an array with elements set to 1
    % if the condition is met and set to 0 if it is not met.
    navBiBinaryBits = (navBiBinaryBits > 0);
    
    %--- Convert from bi-binary to relative code -------------------------
    relNavBits = (navBiBinaryBits(1:2:2549) - ...
                  navBiBinaryBits(2:2:2550) +1 )./2;
              
    %--- Convert from relative code to data sequence and checking bits ---
    navBits(1) = 0;
    navBits(2:1275) = xor(relNavBits(1:1274),relNavBits(2:1275));

    %--- Convert from decimal to binary -----------------------------------
    % The function ephemeris expects input in binary form. In Matlab it is
    % a string array containing only "0" and "1" characters.
    navBitsBin = dec2bin(navBits);
 
    %=== Decode ephemerides and TOD of the first frame ====================
    [eph(channelNr), TOD] = ephemeris(navBitsBin(1:1275)');
    
    %The parameter tau_c is more accurate for GLONASS-M satellites.
    if eph(channelNr).M ~= 0
        tau_c = eph(channelNr).tau_c;
    end
    
    %--- Exclude satellite if it does not have the necessary nav data -----
    if (isempty(eph(channelNr).P1) || ...
        isempty(eph(channelNr).P2) || ...
        isempty(eph(channelNr).P3) || ...
        isempty(eph(channelNr).P4) || ...
        isempty(eph(channelNr).N4))

        %--- Exclude channel from the list (from further processing) ----
        activeChnList = setdiff(activeChnList, channelNr);
    end

end

%% Check if the number of satellites is still above 3 =====================
if (isempty(activeChnList) || (size(activeChnList, 2) < 4))
    % Show error message and exit
    disp('Too few satellites with ephemeris data for postion calculations. Exiting!');
    navSolutions = [];
    eph          = [];
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

transmitTime = TOD;

%##########################################################################
%#   Do the satellite and receiver position calculations                  #
%##########################################################################

%% Initialization of current measurement ==================================
for currMeasNr = 1:fix((settings.msToProcess - max(subFrameStart)) / ...
        settings.navSolPeriod)

    % Exclude satellites, that are belove elevation mask
    activeChnList = intersect(find(satElev >= settings.elevationMask), ...
        readyChnList);

    % Save list of satellites used for position calculation
    navSolutions.channel.K(activeChnList, currMeasNr) = ...
        [trackResults(activeChnList).K];

    % These two lines help the skyPlot function. The satellites excluded
    % do to elevation mask will not "jump" to possition (0,0) in the sky
    % plot.
    navSolutions.channel.el(:, currMeasNr) = ...
        NaN(settings.numberOfChannels, 1);
    navSolutions.channel.az(:, currMeasNr) = ...
        NaN(settings.numberOfChannels, 1);
    %% Find pseudoranges ======================================================
    navSolutions.channel.rawP(:, currMeasNr) = calculatePseudoranges(...
        trackResults, ...
        subFrameStart + settings.navSolPeriod * (currMeasNr-1), ...
        activeChnList, settings);

    %% Find satellites positions and clocks corrections =======================
    [satPositions, satClkCorr] = satpos(transmitTime, ...
        activeChnList, ...
        eph, tau_c);

    %% Find receiver position =================================================

    % 3D receiver position can be found only if signals from more than 3
    % satellites are available
    if size(activeChnList, 2) > 3

        %=== Calculate receiver position ==================================
        [xyzdt, ...
            navSolutions.channel.el(activeChnList, currMeasNr), ...
            navSolutions.channel.az(activeChnList, currMeasNr), ...
            navSolutions.DOP(:, currMeasNr)] = ...
            leastSquarePos(satPositions, ...
            navSolutions.channel.rawP(activeChnList, currMeasNr)' + satClkCorr * settings.c, ...
            settings);

        %--- Save results -------------------------------------------------
        navSolutions.X(currMeasNr)  = xyzdt(1);
        navSolutions.Y(currMeasNr)  = xyzdt(2);
        navSolutions.Z(currMeasNr)  = xyzdt(3);
        navSolutions.dt(currMeasNr) = xyzdt(4);

        % Update the satellites elevations vector
        satElev = navSolutions.channel.el(:, currMeasNr)';  %dma fix for legacy

        %=== Correct pseudorange measurements for clocks errors ===========
        navSolutions.channel.correctedP(activeChnList, currMeasNr) = ...
            navSolutions.channel.rawP(activeChnList, currMeasNr) + ...
            satClkCorr' * settings.c - navSolutions.dt(currMeasNr);

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
        [X,shortestChannel] = min(navSolutions.channel.rawP(:,currMeasNr));
        navSolutions.utmZone = findUtmZone(navSolutions.latitude(currMeasNr), ...
            navSolutions.longitude(currMeasNr));

        [navSolutions.E(currMeasNr), ...
            navSolutions.N(currMeasNr), ...
            navSolutions.U(currMeasNr)] = cart2utm(xyzdt(1), xyzdt(2), ...
            xyzdt(3), ...
            navSolutions.utmZone);

        % Compute the corrected GPS TOW
        navSolutions.GPSTOW(currMeasNr)= transmitTime + ...
            navSolutions.channel.correctedP(shortestChannel,currMeasNr)/settings.c;

        navSolutions.absoluteSample(currMeasNr) =...
            trackResults(shortestChannel).absoluteSample(subFrameStart(shortestChannel) +...
            settings.navSolPeriod * (currMeasNr-1));


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
        navSolutions.GPSTOW                  = NaN;
        navSolutions.absoluteSample          = NaN;

        navSolutions.channel.az(activeChnList, currMeasNr) = ...
            NaN(1, length(activeChnList));
        navSolutions.channel.el(activeChnList, currMeasNr) = ...
            NaN(1, length(activeChnList));

        % TODO: Know issue. Satellite positions are not updated if the
        % satellites are excluded do to elevation mask. Therefore rasing
        % satellites will be not included even if they will be above
        % elevation mask at some point. This would be a good place to
        % update positions of the excluded satellites.



    end % if size(activeChnList, 2) > 3

    %=== Update the transmit time ("measurement time") ====================
    transmitTime = transmitTime + settings.navSolPeriod / 1000;

end %for currMeasNr...
