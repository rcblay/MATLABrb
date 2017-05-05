%function settings = initSettings()
%Functions initializes and saves settings. Settings can be edited inside of
%the function, updated from the command line or updated using a dedicated
%GUI - "setSettings".
%
%All settings are described inside function code.
%
%settings = initSettings()
%
%   Inputs: none
%
%   Outputs:
%       settings     - Receiver settings (a structure).

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis
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

% CVS record:
% $Id: initSettings.m,v 1.9.2.31 2006/08/18 11:41:57 dpl Exp $


%% Processing settings ====================================================
% Number of milliseconds to be processed used 36000 + any transients (see
% below - in Nav parameters) to ensure nav subframes are provided
settings.msToProcess        = 39000;        %[ms]

% Number of channels to be used for signal processing
settings.numberOfChannels   = 1; 

% Move the starting point of processing. Can be used to start the signal
% processing at any point in the data record (e.g. for long records). fseek
% function is used to move the file read point, therefore advance is byte
% based only. For Real sample files it skips the number of bytes as indicated
% here. For I/Q files it skips twice the number of bytes as indicated here
% to consider both I and Q samples
settings.skipNumberOfSamples     = 2; %32;

%% Raw signal file name and other parameter ===============================
% This is a "default" name of the data file (signal record) to be used in
% the post-processing mode

settings.fileName           = '/home/dma/Documents/MATLAB/MATLABrb/nominalout.bin.c0';

% Data type used to store one sample
% options: 'bit1','bit2','bit4','schar','short','int','float','double'
settings.dataType           = 'schar';

% File Types
%1 - 8 bit real samples S0,S1,S2,...
%2 - 8 bit I/Q samples I0,Q0,I1,Q1,I2,Q2,...
settings.fileType           = 1;

%Intermediate, sampling, code and L1 frequencies
settings.IF                 = 14.58e6;      %[Hz]
settings.samplingFreq       = 53e6;     %[Hz]
settings.codeFreqBasis      = 1.023e6;       %[Hz]
settings.L1Freq             = 1575.42e6;   %[Hz]


% Define number of chips in a code period
settings.codeLength         = 1023;

%% Acquisition settings ===================================================
% Skips acquisition in the script postProcessing.m if set to 1
settings.skipAcquisition    = 0;
% List of satellites to look for. Some satellites can be excluded to speed
% up acquisition
settings.acqSatelliteList   = [1:32];
%settings.acqSatelliteList   = [1:37,120:158];
% Band around IF to search fo satellite signal. Depends on max Doppler
settings.acqSearchBand      = 14;           %[kHz]
% Threshold for the signal presence decision rule
settings.acqThreshold       = 1.75;
% No. of code periods for coherent integration (less than 11ms)
settings.acquisition.cohCodePeriods=5;
% No. of non-coherent summations (up to 300ms)
settings.acquisition.nonCohSums=2;

%% Tracking loops settings ================================================
settings.enableFastTracking     = 0;

% Code tracking loop parameters
% dllNoiseBandwidth1 and pllNoiseBandwidth1 are used for signal pull-in,
% and dllNoiseBandwidth2 and pllNoiseBandwidth2 are used then the tracking
% loop is stablized. Usually loopBandwidth2 is smaller to reduce the noise
% and loopBandwidth1 is larger for fast pull-in.
settings.dllDampingRatio          = 0.7;
settings.dllNoiseBandwidth1       = 2;       %[Hz]
settings.dllCorrelatorSpacing     = 0.5;     %[chips]
% Carrier tracking loop parameters
settings.pllDampingRatio          = 0.7;
settings.pllNoiseBandwidth1       = 25;      %[Hz]
% Parameters for second phase of tracking
settings.dllNoiseBandwidth2       = 1;     %[Hz]
settings.pllNoiseBandwidth2       = 10;      %[Hz]
settings.pullInTime               = 600; %500     % ms
% Lock detector constant
settings.ldConstant               = 2;    % Steve used 4.5
% Carrier Phase Inversion
% 1 - has inversion (usually when re-samping IF data)
% 0 - does not have inversion
settings.carrPhaseInversion       = 0;

%% Navigation solution settings ===========================================
% Rate for calculating pseudorange and position
settings.navSolRate         = 1;            %[Hz]
% Elevation mask to exclude signals from satellites at low elevation
settings.elevationMask      = 10;           %[degrees 0 - 90]
% Enable/dissable use of tropospheric correction
settings.useTropCorr        = 0;            % 0 - Off % 1 - On
% Enable/dissable use of ionospheric correction
settings.useIonoCorr        = 1;            % 0 - Off % 1 - On
% Transition time from tracking to navSolution
settings.transition=2;  % seconds
% Velocity Solution Settings
% 1: Use differential carrier phase
% 2: Use reported doppler
settings.velSol=1;
% Clock Steering Option
settings.clkStrAveNum = 10;
settings.clockSteerOn = 1;

% True position of the antenna in UTM system (if known). Otherwise enter
% all NaN's and mean position will be used as a reference .
settings.truePosition.E     = nan;
settings.truePosition.N     = nan;
settings.truePosition.U     = nan;

%% Plot settings ==========================================================
% Enable/disable plotting of the tracking results for each channel
settings.plotTracking       = 1;
% 0 - Off
% 1 - On

%% Constants ==============================================================
settings.c                  = 299792458;    % The speed of light, [m/s]
settings.startOffset        = 68.802;       %[ms] Initial sign. travel time

%% CNo Settings============================================================
% Accumulation interval in Tracking (in Sec)
settings.CNo.accTime=0.001;
% Show C/No during Tracking;1-on;0-off;
settings.CNo.enableVSM=1;
% Accumulation interval for computing VSM C/No (in ms)
settings.CNo.VSMinterval=400;
% Accumulation interval for computing PRM C/No (in ms)
settings.CNo.PRM_K=200;
% No. of samples to calculate narrowband power;
% Possible Values for M=[1,2,4,5,10,20];
% K should be an integral multiple of M i.e. K=nM
settings.CNo.PRM_M=20;
% Accumulation interval for computing MOM C/No (in ms)
settings.CNo.MOMinterval=200;
% Enable/disable the C/No plots for all the channels
% 0 - Off ; 1 - On;
settings.CNo.Plot = 1;

%% settings for rinex files generation
% Enable generation of rinex files
% 0 - Off ; 1 -On;
settings.generateRinex = 0;
% Type of the rinex file
% Non-clockSteering(settings.clockSteerOn = 0)
% 1 - raw measurements (clock bias and drift remain in the measurements)
% 2 - corrected measurement(clock bias and drift removed)
% ClockSteering(settings.clockSteerOn = 1)
% 3 - clock steered, report measurement at integer time
% Autometically set when settings.clockSteerOn = 1
settings.rinexType=1;
% Station name
settings.stationName = 'SDR_UCB';
% File extensions
settings.OBS = 'O';
settings.NAV = 'N';
settings.runBy ='GNSS Lab,UCB';
% Leap Seconds between GPS time and UTC time
settings.leapSec=17; % seconds



