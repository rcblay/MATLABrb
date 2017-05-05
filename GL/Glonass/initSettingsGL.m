function settings = initSettings()
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
settings.skipNumberOfSamples     = 0;

%% Raw signal file name and other parameter ===============================
% This is a "default" name of the data file (signal record) to be used in
% the post-processing mode

settings.fileName           = ...
    '..\dataSets\NT1065_GLONASS_L2_20150831_fs6625e6_60e3_schar_1m.bin';

% Data type used to store one sample
settings.dataType           = 'schar';

% File Types
%1 - 8 bit real samples S0,S1,S2,...
%2 - 8 bit I/Q samples I0,Q0,I1,Q1,I2,Q2,...
settings.fileType           = 2;

%GLONASS L1 or L2 signal (1=L1, 0=L2)
settings.L1L2 = 0;
% Input Center for the data  (1602e6 for L1 or 1246e6 for L2)
settings.inputCenter     = 1246e6;   %[Hz]  %dma not sure this is needed

% Intermediate, sampling and code frequencies

settings.IF                 = 0.0e6;      %[Hz]  %this does not have much meaning if defining the center of the band
settings.samplingFreq       = 6.625e6;    %[Hz]
settings.codeFreqBasis      = 0.511e6;      %[Hz]


% Define number of chips in a code period
settings.codeLength         = 511;

%% Acquisition settings ===================================================
% Skips acquisition in the script postProcessing.m if set to 1
settings.skipAcquisition    = 0;
% List of satellites to look for. Some satellites can be excluded to speed
% up acquisition
settings.acqSatelliteList   = -6:7;         %[Frequency Channel (K)]
% Band around IF to search for satellite signal. Depends on max Doppler
settings.acqSearchBand      = 14;           %[kHz]
% Threshold for the signal presence decision rule
settings.acqThreshold       = 1.7;
% Enable higher sensitivity acquisition % 0 - Off ; 1 - On;
settings.acquisition.enableHighSensitivityAcq=1;
% No. of code periods for coherent integration (multiple of 2)
settings.acquisition.cohCodePeriods=10;
% No. of non-coherent summations
settings.acquisition.nonCohSums=1;

%% Tracking loops settings ================================================
settings.enableFastTracking     = 0;

% Code tracking loop parameters
settings.dllDampingRatio         = 0.7;
settings.dllNoiseBandwidth       = 2.5;       %[Hz]
settings.dllCorrelatorSpacing    = 0.5;     %[chips]

% Carrier tracking loop parameters
settings.pllDampingRatio         = 0.7;
settings.pllNoiseBandwidth       = 25;      %[Hz]

%% Navigation solution settings ===========================================

% Period for calculating pseudoranges and position
settings.navSolPeriod       = 500;          %[ms]

% Elevation mask to exclude signals from satellites at low elevation
settings.elevationMask      = 10;           %[degrees 0 - 90]
% Enable/dissable use of tropospheric correction
settings.useTropCorr        = 1;            % 0 - Off
                                            % 1 - On

% True position of the antenna in UTM system (if known). Otherwise enter
% all NaN's and mean position will be used as a reference .
settings.truePosition.E     = nan;
settings.truePosition.N     = nan;
settings.truePosition.U     = nan;

%% Plot settings ==========================================================
% Enable/disable plotting of the tracking results for each channel
settings.plotTracking       = 1;            % 0 - Off
                                            % 1 - On

%% Constants ==============================================================
settings.c                  = 299792458;    % The speed of light, [m/s]
settings.startOffset        = 65;           %[ms] Initial sign. travel time

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
% Enable/disable the C/No plots for all the channels
% 0 - Off ; 1 - On;
settings.CNo.Plot = 1;