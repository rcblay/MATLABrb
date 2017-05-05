function [trackResults, channel]= trackingC(channel, settings)
% This function is a modified version of the function "tracking" to
% implement C based tracking. This function uses the trackC function to
% perform faster code and carrier tracking for all channels.
%
%[trackResults, channel] = trackingC(channel, settings)
%
%   Inputs:
%       channel         - PRN, carrier frequencies and code phases of all
%                       satellites to be tracked (prepared by preRum.m from
%                       acquisition results).
%       settings        - receiver settings.
%   Outputs:
%       trackResults    - tracking results (structure array). Contains
%                       in-phase prompt outputs and absolute spreading
%                       code's starting positions, together with other
%                       observation data from the tracking loops. All are
%                       saved every millisecond.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Dennis M. Akos
% Written by Darius Plausinaitis and Dennis M. Akos
% Based on code by DMAkos Oct-1999
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
%$Id: tracking.m,v 1.14.2.31 2006/08/14 11:38:22 dpl Exp $



%% Initialize result structure ============================================

% Channel status
trackResults.status         = '-';      % No tracked signal, or lost lock

% The absolute sample in the record of the C/A code start:
trackResults.absoluteSample = zeros(1, settings.msToProcess);

% Freq of the C/A code:
trackResults.codeFreq       = inf(1, settings.msToProcess);

% Frequency of the tracked carrier wave:
trackResults.carrFreq       = inf(1, settings.msToProcess);

% Outputs from the correlators (In-phase):
trackResults.I_P            = zeros(1, settings.msToProcess);
trackResults.I_E            = zeros(1, settings.msToProcess);
trackResults.I_L            = zeros(1, settings.msToProcess);

% Outputs from the correlators (Quadrature-phase):
trackResults.Q_E            = zeros(1, settings.msToProcess);
trackResults.Q_P            = zeros(1, settings.msToProcess);
trackResults.Q_L            = zeros(1, settings.msToProcess);

% Loop discriminators
trackResults.dllDiscr       = inf(1, settings.msToProcess);
trackResults.dllDiscrFilt   = inf(1, settings.msToProcess);
trackResults.pllDiscr       = inf(1, settings.msToProcess);
trackResults.pllDiscrFilt   = inf(1, settings.msToProcess);

%--- Copy initial settings for all channels -------------------------------
trackResults = repmat(trackResults, 1, settings.numberOfChannels);

% Get a vector with the ranging code sampled 1x/chip
prCode = generatePRcode(0,settings.codeFreqBasis,511);
% Then make it possible to do early and late versions
prCode = [prCode(511) prCode prCode(1)];

%% Initialize tracking variables ==========================================

codePeriods = settings.msToProcess;     % For GPS one C/A code is one ms

%--- DLL variables --------------------------------------------------------
% Define early-late offset (in chips)
earlyLateSpc = settings.dllCorrelatorSpacing;

% Summation interval
PDIcode = 0.001;

% Calculate filter coefficient values
[tau1code, tau2code] = calcLoopCoef(settings.dllNoiseBandwidth, ...
    settings.dllDampingRatio, ...
    1.0);

%--- PLL variables --------------------------------------------------------
% Summation interval
PDIcarr = 0.001;

% Calculate filter coefficient values
[tau1carr, tau2carr] = calcLoopCoef(settings.pllNoiseBandwidth, ...
    settings.pllDampingRatio, ...
    0.25);

%% Start processing channels ==============================================
for channelNr = 1:settings.numberOfChannels

    % Only process if PRN is non zero (acquisition was successful)
    if (channel(channelNr).status ~= '-')
        % Save additional information - each channel's tracked PRN
        trackResults(channelNr).PRN     = channel(channelNr).PRN;

        %--- Perform various initializations ------------------------------

        % define initial code frequency basis of NCO
        codeFreq      = settings.codeFreqBasis;
        % define residual code phase (in chips)
        remCodePhase  = 0.0;
        % define carrier frequency which is used over whole tracking period
        carrFreq      = channel(channelNr).acquiredFreq;
        carrFreqBasis = channel(channelNr).acquiredFreq;
        % define residual carrier phase
        remCarrPhase  = 0.0;


        %% Read next block of data ------------------------------------------------
        % Find the size of a "block" or code period in whole samples

        % Update the phasestep based on code freq (variable) and
        % sampling frequency (fixed)
        codePhaseStep = codeFreq / settings.samplingFreq;

        blksize = ceil((settings.codeLength-remCodePhase) / codePhaseStep);


        if (settings.fileType==1)
            dataAdaptCoeff=1;
        else
            dataAdaptCoeff=2;
        end
        skipvalue=settings.skipNumberOfSamples + ...
            channel(channelNr).codePhase-1;

        Ln=sprintf('\n');
        trackingStatus= ['Tracking: Ch ', int2str(channelNr), ...
            ' of ', int2str(settings.numberOfChannels),Ln ...
            'Freq. Ch: #', int2str(channel(channelNr).PRN)];

        %Call the C based tracking function trackC

        try
            [trackResults(channelNr).carrFreq...
                trackResults(channelNr).codeFreq...
                trackResults(channelNr).absoluteSample...
                trackResults(channelNr).dllDiscr...
                trackResults(channelNr).dllDiscrFilt...
                trackResults(channelNr).pllDiscr...
                trackResults(channelNr).pllDiscrFilt...
                trackResults(channelNr).I_E...
                trackResults(channelNr).I_P...
                trackResults(channelNr).I_L...
                trackResults(channelNr).Q_E...
                trackResults(channelNr).Q_P...
                trackResults(channelNr).Q_L...
                trackResults(channelNr).CNo.VSMIndex...
                trackResults(channelNr).CNo.VSMValue] =...
                trackC(prCode,blksize,...
                codePhaseStep,remCodePhase,earlyLateSpc,...
                settings.samplingFreq,remCarrPhase,carrFreq,...
                settings.fileName,skipvalue,tau1carr,tau2carr,...
                PDIcarr,carrFreqBasis,tau1code,tau2code,PDIcode,...
                codeFreq,settings.codeFreqBasis,...
                settings.codeLength,codePeriods,...
                trackingStatus,dataAdaptCoeff,...
                settings.CNo.VSMinterval,settings.CNo.accTime);


        catch
            % The progress bar was closed. It is used as a signal
            % to stop, "cancel" processing. Exit.
            disp('Progress bar closed, exiting...');
            return
        end


        % If we got so far, this means that the tracking was successful
        % Now we only copy status, but it can be update by a lock detector
        % if implemented
        trackResults(channelNr).status  = channel(channelNr).status;

    end % if a PRN is assigned
end % for channelNr

