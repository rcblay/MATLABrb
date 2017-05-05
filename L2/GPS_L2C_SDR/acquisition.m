function acqResults = acquisition(longSignal, settings)
%Function performs cold start acquisition on the collected "data". It
%searches for GPS signals of all satellites, which are listed in field
%"acqSatelliteList" in the settings structure. Function saves code phase
%and frequency of the detected signals in the "acqResults" structure.
%
%acqResults = acquisition(longSignal, settings)
%
%   Inputs:
%       longSignal    - (=20+X+1) ms of raw signal from the 
%                       front-end.The first 20+X ms segment is in order
%                       to include at least the first Xms of a CM code; 
%                       The last 1ms is to make sure the index does not
%                       exceeds matrix dimensions of 10ms long.
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
% Copyright (C) Darius Plausinaitis and Dennis M. Akos
% Written by Yafeng Li
% Based on Peter Rinder and Nicolaj Bertelsen
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
%$Id: acquisition.m,v 1.1.2.12 2006/08/14 12:08:03 dpl Exp $


%% Condition input signal to speed up acquisition ===========================

% If input IF signal freq. is too high, a resampling strategy is applied
% to speed up the acquisition. This is user selectable.
if (settings.samplingFreq > settings.resamplingThreshold && ...
                                       settings.resamplingflag == 1)
   
    %--- Filiter out signal power outside the main lobe of CM code ------------------
    fs = settings.samplingFreq;
    IF = settings.IF;
    % Bandwidth of CM mian lobe
    BW = 1.2e6*2;
    % Filter parameter
    w1 = (IF)-BW/2;
    w2 = (IF)+BW/2;
    wp = [w1*2/fs-0.002 w2*2/fs+0.002];
    % Filter coefficients
    b  = fir1(700,wp);
    % Filter operation
    longSignal = filtfilt(b,1,longSignal);
    
    % --- Find resample frequency ---------------------------------------------------
    % Refer to bandpass sampling theorem(Yi-Ran Sun,Generalized Bandpass
    % Sampling Receivers for Software Defined Radio)
    
    % Upper boundary frequency of the bandpass IF signal
    fu = settings.IF + BW/2;
    
    % Lower freq. of the acceptable sampling Freq. range
    n = floor(fu/BW);
    if (n<1)
        n = 1;
    end
    lowerFreq = 2*fu/n;
    
    % Lower boundary frequency of the bandpass IF signal
    fl = settings.IF - BW/2;
    
    % Upper boundary frequency of the acceptable sampling Freq. range
    if(n>1)
        upperFreq = 2*fl/(n-1);
    else
        upperFreq = lowerFreq;
    end
    
    % Save orignal Freq. for later use
    oldFreq = settings.samplingFreq;
    
    % Take the center of the acceptable sampling Freq. range as
    % resampling frequency. As settings are used to generate local
    % CM code samples, so assign the resampling freq. to settings.
    % This can not change the settings.samplingFreq outside this 
    % acquisition function.
    settings.samplingFreq = ceil((lowerFreq + upperFreq)/2);
    
    %--- Downsample input IF signal -------------------------------------------------
    % Signal length after resampling
    signalLen = floor((length(longSignal)-1) /oldFreq * settings.samplingFreq);
    % Resampled signal index
    index = ceil((0:signalLen-1)/settings.samplingFreq * oldFreq);
    index(1) = 1;
    % Resampled signal
    longSignal = longSignal(index);
    
    % Foe latter use
    oldIF = settings.IF;
    
    % Resampling is equivalent to down-converting the original IF by integer
    % times of resampling freq.. So the IF after resampling is equivalent to:
    settings.IF = rem(settings.IF,settings.samplingFreq);

end % resampling input IF signals

%% Acquisition initialization ===============================================

%--- Find number of samples for fiffernet long signals ------------------------------
% Number of samples per spreading code
samplesPerCode = round(settings.samplingFreq / ...
                        (settings.codeFreqBasis / settings.codeLength));              
% Number of samples of settings.acqCohT CM spreading codes
samplesXmsLen= round(samplesPerCode /20*settings.acqCohT);
% Number of samples of 20 plus acqCohT(X) ms CM spreading codes
len20PlusXms = round(samplesPerCode /20*(20+settings.acqCohT));
% Find number of samples of 10ms CM spreading codes
samples10msLength = round(samplesPerCode /20*10);
% Find number of samples per CM code chip
samplesPerCodeChip   = ceil(settings.samplingFreq / settings.codeFreqBasis);

%--- Cut 20 plus X cm input signal to do correlate ----------------------------------
sig20PlusXms = longSignal(1:len20PlusXms);

%--- Generate input and local signal to to correlate ------------------------
% Find sampling period
ts = 1 / settings.samplingFreq;
% Find phase points of the local carrier wave 
phasePoints = (0 : (len20PlusXms-1)) * 2 * pi * ts;

% Number of the frequency bins for the given acquisition band
numberOfFrqBins = round(settings.acqSearchBand * 2 / settings.acqStep) + 1;

%--- Initialize arrays to speed up the code -----------------------------------
% Search results of all frequency bins and code shifts (for one satellite)
results     = zeros(numberOfFrqBins, len20PlusXms);

% Carrier frequencies of the frequency bins
frqBins     = zeros(1, numberOfFrqBins);

%--- Initialize acqResults and related variables -----------------------------
% Carrier frequencies of detected signals
acqResults.carrFreq     = zeros(1, 32);
% CM code phases of detected signals
acqResults.codePhase    = zeros(1, 32);
% Correlation peak ratios of the detected signals
acqResults.peakMetric   = zeros(1, 32);

fprintf('(');

% Perform search for all listed PRN numbers ...
for PRN = settings.acqSatelliteList

%% Correlate signals ======================================================   
    
    % Generate all CM codes and sample them according to the sampling freq.
    cmCodesTable = makeCMTable(settings,PRN);
    % generate local code duplicate to do correlate
    localCode = [cmCodesTable(1:samplesXmsLen) ...
                    zeros(1,len20PlusXms - samplesXmsLen)];
    
    %--- Perform DFT of CM code ------------------------------------------
    cmCodeFreqDom = conj(fft(localCode));

    %--- Make the correlation for whole frequency band (for all freq. bins)
    for frqBinIndex = 1:numberOfFrqBins

        %--- Generate carrier wave frequency grid  -----------------------
        frqBins(frqBinIndex) = settings.IF - settings.acqSearchBand + ...
                               settings.acqStep * (frqBinIndex - 1);

        %--- Generate local sine and cosine -------------------------------
        sigCarr = exp(1i*frqBins(frqBinIndex) * phasePoints);
        
        %--- "Remove carrier" from the signal -----------------------------
        I1      = real(sigCarr .* sig20PlusXms);
        Q1      = imag(sigCarr .* sig20PlusXms);

        %--- Convert the baseband signal to frequency domain --------------
        IQfreqDom1 = fft(I1 + 1i*Q1);

        %--- Multiplication in the frequency domain (correlation in time
        %domain)
        convCodeIQ1 = IQfreqDom1 .* cmCodeFreqDom;

        %--- Perform inverse DFT and store correlation results ------------
        results(frqBinIndex, :) = abs(ifft(convCodeIQ1));
        
%         surf(results)
        
    end % frqBinIndex = 1:numberOfFrqBins

%% Look for correlation peaks in the results ==============================
    % Find the highest peak and compare it to the second highest peak
    % The second peak is chosen not closer than 1 chip to the highest peak
    
    %--- Find the correlation peak and the carrier frequency --------------
    [peakSize frequencyBinIndex] = max(max(results, [], 2));

    %--- Find code phase of the same correlation peak ---------------------
    [peakSize codePhase] = max(max(results));

    %--- Find 1 chip wide CM code phase exclude range around the peak ----
    excludeRangeIndex1 = codePhase - samplesPerCodeChip;
    excludeRangeIndex2 = codePhase + samplesPerCodeChip;
    % Exclude range around the peak within X ms CM code period.
    excludeRangeIndex3 = codePhase - samplesXmsLen + samplesPerCodeChip;
    excludeRangeIndex4 = codePhase + samplesXmsLen - samplesPerCodeChip;

    %--- Correct CM code phase exclude range if the range 
    % includes array boundaries -------------------------------------------
    % The left including range before the peak
    if excludeRangeIndex1 < 1
        leftRange = [];        
    else
        leftRange = max(1,excludeRangeIndex3): excludeRangeIndex1;
    end
    % The right including range after the peak
    if excludeRangeIndex2 >= len20PlusXms
        rightRange = [];
    else
        rightRange = excludeRangeIndex2: ...
            min(excludeRangeIndex4,len20PlusXms);
    end
    
    % Combine the left and right Ranges together
    codePhaseRange = [leftRange rightRange];

    %--- Find the second highest correlation peak in the same freq. bin ---
    secondPeakSize = max(results(frequencyBinIndex, codePhaseRange));

    %--- Store result -----------------------------------------------------
    acqResults.peakMetric(PRN) = peakSize/secondPeakSize;
    
    % If settings.acqCohT is more than 10ms, then use settings.acqCohT ms
    % signal to do fine acquisition.
    if(settings.acqCohT <=10)
        findLen = samples10msLength;
    else
        findLen = samplesXmsLen;
    end
    
    % To prevent index form exceeding matrix dimensions. Move to previous
    % code start position.
    if (codePhase+findLen-1) > length(longSignal)
        codePhase = codePhase - samplesPerCode;  
    end
    
    % If the result is above threshold, then there is a signal ...
    if (peakSize/secondPeakSize) > settings.acqThreshold &&...
            (codePhase+findLen-1) < length(longSignal)

%% Fine resolution frequency search =======================================
        
        %--- Indicate PRN number of the detected signal -------------------
        fprintf('%02d ', PRN);
        
        %--- Generate 10msec long CM codes sequence -----------------------       
        longCaCode = cmCodesTable(1:findLen);
        
        % Cut 10ms input signal one with zero DC --------------------------
        % Using detected CM code phase
        signal0DC = longSignal(codePhase:(codePhase + findLen-1));
        signal0DC = signal0DC - mean(signal0DC);
        
        %--- Remove CM code modulation from the original signal ---------- 
        xCarrier = signal0DC .* longCaCode;
        
        %--- Compute the magnitude of the FFT, find maximum and the
        %associated carrier frequency
        
        %--- Find the next highest power of two and increase by 8x --------
        fftNumPts = 8*(2^(nextpow2(length(xCarrier))));
        
        %--- Compute the magnitude of the FFT, find maximum and the
        %associated carrier frequency
        fftxc = abs(fft(xCarrier, fftNumPts));
        
        uniqFftPts = ceil((fftNumPts + 1) / 2);
        [fftMax, fftMaxIndex] = max(fftxc);
        fftFreqBins = (0 : uniqFftPts-1) * settings.samplingFreq/fftNumPts;
        if (fftMaxIndex > uniqFftPts) %and should validate using complex data
            if (rem(fftNumPts,2)==0)  %even number of points, so DC and Fs/2 computed
                fftFreqBinsRev=-fftFreqBins((uniqFftPts-1):-1:2);
                [fftMax, fftMaxIndex] = max(fftxc((uniqFftPts+1):length(fftxc)));
                acqResults.carrFreq(PRN)  = -fftFreqBinsRev(fftMaxIndex);
            else  %odd points so only DC is not included
                fftFreqBinsRev=-fftFreqBins((uniqFftPts):-1:2);
                [fftMax, fftMaxIndex] = max(fftxc((uniqFftPts+1):length(fftxc)));
                acqResults.carrFreq(PRN)  = fftFreqBinsRev(fftMaxIndex);
            end
        else
            acqResults.carrFreq(PRN)  = (-1)^(settings.fileType-1)*fftFreqBins(fftMaxIndex);
        end
        
        %signal found, if IF =0 just change to 1 Hz to allow processing
        if(acqResults.carrFreq(PRN) == 0)
            acqResults.carrFreq(PRN) = 1;
        end
        
        acqResults.codePhase(PRN) = codePhase;
        
        %--- Find acquisition results corresponding to orignal sampling freq.--------
        if (exist('oldFreq', 'var') && settings.resamplingflag == 1)
            % Find code phase
            acqResults.codePhase(PRN) = floor((codePhase - 1)/ ...
                                        settings.samplingFreq *oldFreq)+1;
            
            % Doppler freq.
            doppler = acqResults.carrFreq(PRN) - settings.IF;
            % Carrier freq. corresponding to orignal sampling freq
            acqResults.carrFreq(PRN) = doppler + oldIF;
        end
           
    else
        %--- No signal with this PRN --------------------------------------
        fprintf('. ');
    end   % if (peakSize/secondPeakSize) > settings.acqThreshold
    
end    % for PRN = satelliteList

%=== Acquisition is over ==================================================
fprintf(')\n');
