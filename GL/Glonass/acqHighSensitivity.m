function acqResults = acqHighSensitivity(signal, settings)
%Function performs cold start acquisition on the collected "data". It
%searches for GPS signals of all satellites, which are listed in field
%"acqSatelliteList" in the settings structure. Function saves code phase
%and frequency of the detected signals in the "acqResults" structure.
%
%acqResults = acqHighSensitivity(signal, settings)
%
%   Inputs:
%       signal        - raw signal from the front-end
%       settings      - Receiver settings. Provides information about
%                       sampling and intermediate frequencies and other
%                       parameters including the list of the satellites to
%                       be acquired.
%   Outputs:
%       acqResults    - Function saves code phases and frequencies of the
%                       detected signals in the "acqResults" structure. The
%                       field "carrFreq" is set to 0 if the signal is not
%                       detected for the given PRN number.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Dennis M. Akos
% Written by Sirish Jetti
% Based on Eric Vinande and Dennis Akos
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


%% Initialization =========================================================

% Find number of samples per spreading code
samplesPerCode = round(settings.samplingFreq / ...
    (settings.codeFreqBasis / settings.codeLength));

%Create a signal with zero DC
signal0DC = signal - mean(signal);

% C/A code frequency
chipRate        = settings.codeFreqBasis;
% C/A code length
codeLength      = settings.codeLength;
% No. of code periods for coherent integration
cohCodePeriods  = settings.acquisition.cohCodePeriods;
% Doppler Search Band in Hz
doppSearchBand  = settings.acqSearchBand*1000;%In Hz
% Sampling Frequency
samplingFreq    = settings.samplingFreq;
% Sampling period
ts              = 1 / settings.samplingFreq;
% FFT Length should be at least 2*code_length*coh_code_periods
fftLength       = 2^ceil(log2(2*codeLength*cohCodePeriods));
samplesPerChip  = fftLength / (codeLength * cohCodePeriods);
freqStep        = chipRate / (codeLength * cohCodePeriods);
% No. of frequency bins to search on each side
freqBins        = doppSearchBand/freqStep;
% Samples per each coherent sum
NoOfSamples     = (samplingFreq/chipRate) * codeLength * cohCodePeriods;

%Get the sampled code and compute the FFT
[X sampledCode] = rangingCode(0,samplesPerChip*chipRate,fftLength);
fftCode = fft(sampledCode);
fftConjCode = conj(fftCode);

% Generate 10msec long PR ranging code
[Y longPRCode] = rangingCode(0,settings.samplingFreq,10*samplesPerCode);


%% Remove Carrier and Resample ============================================
% No. of non-coherent summations
nonCohSums      = settings.acquisition.nonCohSums;
cohSamplesNo    = floor(NoOfSamples);

inputfftA = zeros(nonCohSums,fftLength);
inputfftB = zeros(nonCohSums,fftLength);

% Resample parameters
[resampleNum,resampleDenom] = rat(fftLength/NoOfSamples);

%--- Initialize acqResults ------------------------------------------------
% Carrier frequencies of detected signals
acqResults.carrFreq     = zeros(1, 21);
% C/A code phases of detected signals
acqResults.codePhase    = zeros(1, 21);
% Correlation peak ratios of the detected signals
acqResults.peakMetric   = zeros(1, 21);

%% Remove Code and Correlate ==============================================
fprintf('(');

%-----For each PRN in the acqSatellite list--------------------------------
for K = settings.acqSatelliteList

    % Phase Points
%L1 has 562.5e3*K spacing while L2 has  437.5e3*K spacing (diff of 125 kHz)
    expPhasePoints = exp(i*2*pi*(settings.IF + ...
        437.5e3*K + (settings.L1L2 * 125e3*K) ...
                               )*ts*(0:(cohSamplesNo-1)));
                                                      
    for index = 1:nonCohSums

        % Read alternate signal block
        signalA = signal(2*(index-1)*cohSamplesNo+1:2*(index-1)*cohSamplesNo+cohSamplesNo);
        signalB = signal((2*index-1)*cohSamplesNo+1:2*index*cohSamplesNo);

        % Remove the carrier
        inputA = expPhasePoints .* signalA;
        inputB = expPhasePoints .* signalB;

        % Resample the baseband signal
        inputA_resamp = resample(inputA,resampleNum,resampleDenom);
        inputB_resamp = resample(inputB,resampleNum,resampleDenom);

        % Convert the baseband signal to frequency domain
        inputfftA(index,:) = fft(inputA_resamp(1:length(inputfftA)));
        inputfftB(index,:) = fft(inputB_resamp(1:length(inputfftB)));

    end

    maxCorrAmount = 0;
    freqIndex = 0;

    % For each Doppler search bin
    for binIndex =-freqBins:freqBins

        freqIndex = freqIndex + 1;
        corrA = zeros(1,fftLength);
        corrB = zeros(1,fftLength);

        %Loop through the non-coherent sums
        for index = 1:nonCohSums

            %Circular shift the baseband in frequency domain
            inputfftA_shift = circshift(inputfftA(index,:),[0,binIndex]);
            inputfftB_shift = circshift(inputfftB(index,:),[0,binIndex]);

            %Correlate with the code
            mixed_fftsA = inputfftA_shift .* fftConjCode;
            mixed_fftsB = inputfftB_shift .* fftConjCode;

            %Compute IFFT and sum the results for non-coherent summation
            corrA = corrA + abs(ifft(mixed_fftsA));
            corrB = corrB + abs(ifft(mixed_fftsB));

        end

        %---Find the maximum correlation and store the results---------
        maxCorrA = max(corrA);
        maxCorrB = max(corrB);

        maxCorrCurrentFreq = max(maxCorrA,maxCorrB);

        if ( maxCorrCurrentFreq > maxCorrAmount )
            maxCorrAmount = maxCorrCurrentFreq;
            maxCorrFreqIndex = freqIndex;
            if ( maxCorrB > maxCorrA )
                maxCorr1ms = corrB(1:round(samplesPerChip*codeLength));
            else
                maxCorr1ms = corrA(1:round(samplesPerChip*codeLength));
            end
        end

    end

    acqCarrFreq = (maxCorrFreqIndex - (freqBins+1))*freqStep + ...
    settings.IF + settings.inputCenter + (437.5e3*K + (settings.L1L2 * 125e3*K)) - settings.inputCenter;

    % Calculate the Peak Height
    [peakHeight,codephaseIndex] = max(maxCorr1ms);

    %----Calculate the second highest peak (maximum noise)-----------------
    if ( codephaseIndex + 2*ceil(samplesPerChip) > length(maxCorr1ms) )    % peak near end of code period
        noise_max = max( maxCorr1ms(1:codephaseIndex - 2*ceil(samplesPerChip)) );
    elseif ( codephaseIndex - 2*ceil(samplesPerChip) < 1 )                 % peak near beginning of code period
        noise_max = max( maxCorr1ms(  codephaseIndex + 2*ceil(samplesPerChip):end) ) ;
    else
        noise_max = max( max(maxCorr1ms(1:codephaseIndex - 2*ceil(samplesPerChip))), ...
            max(maxCorr1ms(  codephaseIndex + 2*ceil(samplesPerChip):end)) );
    end

    % Calculate the Peak Metric and the Code Phase
    acqResults.peakMetric(K+8)  = peakHeight / noise_max;
    acqResults.codePhase(K+8)   = round((codephaseIndex/(fftLength/cohCodePeriods))*(samplingFreq/(chipRate/codeLength)));

    if (acqResults.peakMetric(K+8)) > settings.acqThreshold
        fprintf('%02d ', K);

        %Fine Frequency Search

        %--- Remove C/A code modulation from the original signal ----------
        % (Using detected C/A code phase)
        xCarrier = ...
            signal0DC(acqResults.codePhase(K+8):(acqResults.codePhase(K+8) + 10*samplesPerCode-1)) ...
            .* longPRCode;

        %--- Find the next highest power of two and increase by 8x --------
        fftNumPts = 8*(2^(nextpow2(length(xCarrier))));

        %--- Compute the magnitude of the FFT, find maximum and the
        %associated carrier frequency

        fftxCarrier=fft(xCarrier, fftNumPts);
        Amp=fftshift(fftxCarrier.*conj(fftxCarrier));
        fftFreqBins=-samplingFreq/2:samplingFreq/fftNumPts:...
            samplingFreq/2-samplingFreq/fftNumPts;
        [v,indMin]=min(abs(fftFreqBins+acqCarrFreq+1000/cohCodePeriods));
        [v,indMax]=min(abs(fftFreqBins+acqCarrFreq-1000/cohCodePeriods));
        Amp2 = Amp;
        Amp2(1:indMin-1)=0;
        Amp2(indMax+1:end)=0;
        [v,maxInd] = max(Amp2);
        acqResults.carrFreq(K+8)  = -fftFreqBins(maxInd);

    else
        fprintf('. ');
    end

end


fprintf(')\n');