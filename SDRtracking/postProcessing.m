% Script postProcessing.m processes the raw signal from the specified data
% file (in settings) operating on blocks of 37 seconds of data.
%
% First it runs acquisition code identifying the satellites in the file,
% then the code and carrier for each of the satellites are tracked, storing
% the 1msec accumulations.  After processing all satellites in the 37 sec
% data block, then postNavigation is called. It calculates pseudoranges
% and attempts a position solutions. At the end plots are made for that
% block of data.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis, Dennis M. Akos
% Some ideas by Dennis M. Akos
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

%                         THE SCRIPT "RECIPE"
%
% The purpose of this script is to combine all parts of the software
% receiver.
%
% 1.1) Open the data file for the processing and seek to desired point.
%
% 2.1) Acquire satellites
%
% 3.1) Initialize channels (preRun.m).
% 3.2) Pass the channel structure and the file identifier to the tracking
% function. It will read and process the data. The tracking results are
% stored in the trackResults structure. The results can be accessed this
% way (the results are stored each millisecond):
% trackResults(channelNumber).XXX(fromMillisecond : toMillisecond), where
% XXX is a field name of the result (e.g. I_P, codePhase etc.)
%
% 4) Pass tracking results to the navigation solution function. It will
% decode navigation messages, find satellite positions, measure
% pseudoranges and find receiver position.
%
% 5) Plot the results.

%% Initialization =========================================================
%disp ('Starting processing...');

[fid, message] = fopen(settings.fileName, 'rb');

%Initialize the multiplier to adjust for the data type
if (settings.fileType==1)
    dataAdaptCoeff=1;
else
    dataAdaptCoeff=2;
end

%Find the coefficient of samples per byte 
sbCoeff=sample2Byte(settings);

%If success, then process the data
if (fid > 0)

    % Move the starting point of processing. Can be used to start the
    % signal processing at any point in the data record (e.g. good for long
    % records or for signal processing in blocks).
    if ((fseek(fid, round(dataAdaptCoeff*sbCoeff*settings.skipNumberOfSamples), 'bof')) ~= 0)
        disp('desired fseek in postProcessing failed...')
    end
   

    %% Acquisition ============================================================

    % Do acquisition if it is not disabled in settings or if the variable
    % acqResults does not exist.
    if ((settings.skipAcquisition == 0) || ~exist('acqResults', 'var'))

        % Find number of samples per spreading code
        samplesPerCode = round(settings.samplingFreq / ...
            (settings.codeFreqBasis / settings.codeLength));



        %--- Do the acquisition -------------------------------------------
        %disp ('   Acquiring satellites...');

        % Read the required amount of data depending on the data file type
        % and the number of code period of coherent and non-coherent 
        % integration and invoke the acquisition function
        
        
        % Ensure the data read is longer than 20 ms for fine frequency
        % search
        if settings.acquisition.cohCodePeriods * ...
                settings.acquisition.nonCohSums+1 > 10
            data = fread(fid, ...
                dataAdaptCoeff*(settings.acquisition.cohCodePeriods*...
                settings.acquisition.nonCohSums+1)*samplesPerCode*2, ...
                settings.dataType)';
        else
            data = fread(fid, ...
                dataAdaptCoeff*(21*samplesPerCode),settings.dataType)';
        end
        
        % Map the value of data read from the bit1 or bit2 data file
        if strcmp(settings.dataType,'bit1')==1 || strcmp(settings.dataType,'bit2')==1
            data=mapBits(data,settings.dataType);
        end
            
        % 1. If the data is complex, then make the combination of I-j*Q to
        % swap the signal spectrum. Then this swapped incoming signal 
        % will correlate with the local signal have the IF carrier remove
        % 2. If we combine the signal as I+j*Q, the local signal wouldn't be able
        % to remove the IF carrier or the reported doppler will in its
        % negative value if the nominal IF is set to be zero
        % 3. In fine frequency search, the incoming signal will be swap
        % back to I+j*Q, since at that stage, it wouldn't correlate with
        % the local carrier
        if (dataAdaptCoeff==2)
            data1=data(1:2:end);
            data2=data(2:2:end);
            data=data1 - i .* data2;
        end

        acqResults = acquisition(data, settings);
        % Plot the acquisition results
        plotAcquisition(acqResults,settings);
        
    end

    %% Initialize channels and prepare for the run ============================

    % Start further processing only if a GNSS signal was acquired (the
    % field FREQUENCY will be set to 0 for all not acquired signals)
    if (any(acqResults.peakMetric>settings.acqThreshold))
        channel = preRun(acqResults, settings);
        showChannelStatus(channel, settings);
    else
        % No satellites to track, exit
        disp('No GNSS signals detected, signal processing finished.');
        trackResults = [];
        return;
    end

    %% Track the signal =======================================================
    startTime = now;
    %disp (['   Tracking started at ', datestr(startTime)]);

    % Process all channels for given data block
    if (settings.enableFastTracking == 1)
        [trackResults, channel] = trackingC(channel, settings);
    else
        [trackResults, channel] = tracking(fid, channel, settings);
    end
    % Close the data file
    fclose('all');

    %disp(['   Tracking is over (elapsed time ', datestr(now - startTime, 13), ')'])


    %Compute the PRM C/No and add it to the track results
    trackResults = calculateCNoPRM(trackResults,settings);
    %Compute the MOM C/No and add it to the track results
    trackResults = calculateCNoMOM(trackResults,settings);

    % Auto save the acquisition & tracking results to a file to allow
    % running the positioning solution afterwards.
    %disp('   Saving Acq & Tracking results to file "trackingResults.mat"') %is this the correct place to save the file?
    %some crazy text manipulation to get the filename into the track
    %results
    if ((max(size(strfind(settings.fileName,'\'))))>0)
        myTfname=settings.fileName((1+max(strfind(settings.fileName,'\'))):end-4);
    else
        myTfname=settings.fileName(1:end-4);
    end
    
    eval([' save(''trackingResults_',myTfname,''',''trackResults'', ''settings'', ''acqResults'', ''channel''); '])

    %% Calculate navigation solutions =========================================
    %disp('   Calculating navigation solutions...');
    [navSolutions, eph] = postNavigation(trackResults, settings);
    
    %% Generate Rinex Files
    if isempty(navSolutions)~=1 && settings.generateRinex == 1 && isnan(navSolutions.rxTime(1))~=1 
        %disp('   Generating Rinex Nav/Obs Files...');
        rinexData=conversion(navSolutions,eph,settings);
        genRinexFiles(rinexData,settings);
        save('rinexData.mat','navSolutions','eph','rinexData','settings');
    else
        %disp('No Rinex File is generated');
    end

    %disp('   Processing is complete for this data block');

    %% Plot all results ===================================================
    %disp ('   Ploting results...');
    if settings.plotTracking
        %plotTracking(1:settings.numberOfChannels, trackResults, settings);
    end

    %plotNavigation(navSolutions, settings);
    
    %disp('Post processing of the signal is over.');
    
else
    % Error while opening the data file.
    error('Unable to read file %s: %s.', settings.fileName, message);
end % if (fid > 0)

