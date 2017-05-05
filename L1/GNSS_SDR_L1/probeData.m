function probeData(varargin)
%Function plots raw data information: time domain plot, a frequency domain
%plot and a histogram.
%
%The function can be called in two ways:
%   probeData(settings)
% or
%   probeData(fileName, settings)
%
%   Inputs:
%       fileName        - name of the data file. File name is read from
%                       settings if parameter fileName is not provided.
%
%       settings        - receiver settings. Type of data file, sampling
%                       frequency and the default filename are specified
%                       here.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Dennis M. Akos
% Written by Darius Plausinaitis and Dennis M. Akos
% Modified by Eric Horacek
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
% $Id: probeData.m,v 1.1.2.7 2006/08/22 13:46:00 dpl Exp $
% _________________________________________________________________________
init;
%% Check the number of arguments ==========================================
if (nargin == 1)
    settings = deal(varargin{1});
    fileNameStr = settings.fileName;
elseif (nargin == 2)
    [fileName, settings] = deal(varargin{1:2});
    if ~ischar(fileName)
        error('File name must be a string');
    end
else
    error('Incorect number of arguments');
end

%Find the coefficient of samples per byte 
sbCoeff=sample2Byte(settings);

%% Generate plot of raw data ==============================================
if (nargin == 1)
    fileNamestr = fileNameStr;
    [fid, message] = fopen(fileNamestr, 'rb');
else
    fileNamestr = fileName;
    [fid, message] = fopen([folder, '/', fileNamestr], 'rb');
end

if (fid > 0)
    if (settings.fileType==1)
        dataAdaptCoeff=1;
    else
        dataAdaptCoeff=2;
    end
    
    % Move the starting point of processing. Can be used to start the
    % signal processing at any point in the data record (e.g. for long
    % records).
    if ((fseek(fid, round(settings.skipNumberOfSamples*sbCoeff*dataAdaptCoeff), 'bof')) ~= 0)
    %if ((fseek(fid, round(10000*sbCoeff*dataAdaptCoeff), 'bof')) ~= 0)
        disp('desired fseek in probeData failed...')
    end
    
    % Find number of samples per spreading code
    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    % Read 200ms of signal
    [data, count] = fread(fid, [1, dataAdaptCoeff*200*samplesPerCode], settings.dataType);
    
    % Map the value of data read from the bit1 or bit2 data file
    if strcmp(settings.dataType,'bit1')==1 || strcmp(settings.dataType,'bit2')==1
        data=mapBits(data,settings.dataType);
    end


    fclose(fid);

    if (count < dataAdaptCoeff*200*samplesPerCode)
        % The file is to short
        error('Could not read enough data from the data file.');
    end

    %--- Initialization ---------------------------------------------------
    
    if (ishandle(100))        
        clf(100);
    else
        fh = figure(100);
    
        screenSize=get(0,'ScreenSize');
        figWidth=900;
        figHeight=600;
        figPosition=[0.5*(screenSize(3)-figWidth),...
            0.5*(screenSize(4)-figHeight),figWidth,figHeight];
        set(fh,'Position',figPosition);

        clf(100);
    end
    
    %Scale of position plot
    
    if (strcmp(settings.dataType,'bit1'))
        dataTypeBitSize = 1;
    elseif (strcmp(settings.dataType,'bit2'))
        dataTypeBitSize = 2;
    elseif (strcmp(settings.dataType,'bit4'))
        dataTypeBitSize = 4;
    elseif (strcmp(settings.dataType,'schar'))
        dataTypeBitSize = 8;
    elseif (strcmp(settings.dataType,'short'))
        dataTypeBitSize = 16;
    elseif (strcmp(settings.dataType,'int'))
        dataTypeBitSize = 32;
    elseif (strcmp(settings.dataType,'float'))
        dataTypeBitSize = 32;
    elseif (strcmp(settings.dataType,'double'))
        dataTypeBitSize = 64;
    else
        error('Unknown data type defined.');
    end
    
    if (nargin == 1)
        fileNamestr = fileNameStr;
        fdir = dir(fileNamestr);
    else
        fileNamestr = fileName;
        fdir = dir([folder,'/',fileNamestr]);
    end
    totalBits = fdir.bytes*8;
    fileSizeInSamples = ((totalBits/dataTypeBitSize)/dataAdaptCoeff);
    
    %max position is 200ms before end of file or 0 if smaller
    maxSamplePos = fileSizeInSamples - (dataAdaptCoeff*200*samplesPerCode);
    %in samples
    positionScale.Min = 0;
    positionScale.Mid = settings.skipNumberOfSamples;
    positionScale.Max = maxSamplePos;
    
    %in ms
    positionScaleMs.Min = 0;
    positionScaleMs.Mid = (settings.samplingFreq)^(-1)*positionScale.Mid;
    positionScaleMs.Max = (settings.samplingFreq)^(-1)*positionScale.Max;
    
    %Scales of time domain plot in samples
    timeDomainScale.MinSamp = 2;
    global TDLScale;
    
    if (size(TDLScale) == 0)
        TDLScale = 100;
    end

    timeDomainScale.MidSamp = TDLScale;
    %200 ms of samples (1/5th of a second)
    timeDomainScale.MaxSamp = (settings.samplingFreq)/5;
    
    if (TDLScale > timeDomainScale.MaxSamp)
        TDLScale = (settings.samplingFreq)/5;
    end
    
    %scales of time domain plot in ms
    %smallest scale is with two samples on graph    
    timeDomainScale.Min = (settings.samplingFreq)^(-1) * timeDomainScale.MinSamp * 1000;
    timeDomainScale.Mid = (settings.samplingFreq)^(-1) * timeDomainScale.MidSamp * 1000;
    timeDomainScale.Max = (settings.samplingFreq)^(-1) * timeDomainScale.MaxSamp * 1000;
    
    %time scale from 0 to 200 ms
    timeScale = 0 : 1/settings.samplingFreq : 200e-3;
    
    global HFLScale;
    
    if (size(HFLScale) == 0)
        HFLScale = (settings.samplingFreq)/20;
    end
    
    %Scales of histogram/frequency plot in samples
    %32758 samples is defined minimum for frequency plot
    histogramFrequencyScale.MinSamp = 32758;
    %50 ms of samples (1/20th of a second)
    histogramFrequencyScale.MidSamp = HFLScale;
    %200 ms of samples (1/5th of a second)
    histogramFrequencyScale.MaxSamp = (settings.samplingFreq)/5;
    
    if (HFLScale > histogramFrequencyScale.MaxSamp)
        HFLScale = (settings.samplingFreq)/5;
    end
    
    %Scales of histogram/frenquency plots in ms
    histogramFrequencyScale.Min = (settings.samplingFreq)^(-1) * histogramFrequencyScale.MinSamp * 1000;
    histogramFrequencyScale.Mid = (settings.samplingFreq)^(-1) * histogramFrequencyScale.MidSamp * 1000;
    histogramFrequencyScale.Max = (settings.samplingFreq)^(-1) * histogramFrequencyScale.MaxSamp * 1000;
    
    %Panel to hold the graphs
    GraphPanel = uipanel('Position',[0 .115 1 .91], 'BackgroundColor',[.7 .7 .7]);

    %--- Time domain plot -------------------------------------------------

    scale = 1000 * (settings.samplingFreq)^(-1) * timeDomainScale.MidSamp;
    
    if (settings.fileType==1)

        subplot(2, 2, 3, 'Parent', GraphPanel);
        plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
            data(1:round(samplesPerCode*scale)));

        axis tight;    grid on;
        title ('Time domain plot');
        xlabel('Time (ms)'); ylabel('Amplitude');
    else
        data=data(1:2:end) + 1i .* data(2:2:end);
        subplot(3, 2, 4, 'Parent', GraphPanel);
        plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
            real(data(1:round(samplesPerCode*scale))));

        axis tight;    grid on;
        title ('Time domain plot (I)');
        xlabel('Time (ms)'); ylabel('Amplitude');

        subplot(3, 2, 3, 'Parent', GraphPanel);
        plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
            imag(data(1:round(samplesPerCode*scale))));

        axis tight;    grid on;
        title ('Time domain plot (Q)');
        xlabel('Time (ms)'); ylabel('Amplitude');

    end
    
    %Time Domain Plot Length Panel
    TDLpanel = uipanel('Title','Time Domain Length (samples), (ms)','FontSize',8,...
        'Position',[0 0 .495 .0575], 'BackgroundColor',[.7 .7 .7]);
    
    %Time Domain Plot Length Slider/Display
    uicontrol('Parent',TDLpanel,'Style','slider','Tag','TDPRslid',...
    'Max',timeDomainScale.Max,'Min',timeDomainScale.Min,'Value',timeDomainScale.Mid,...
    'SliderStep',[0.0001 0.01],'Position',[147 2 294 18],...
    'Callback',{@TDLSliderCallback,samplesPerCode,data,settings.fileType,timeScale, GraphPanel, settings.samplingFreq});

    uicontrol('Parent',TDLpanel,'Style','edit','Tag','TDPRdispSamp',...
    'String',num2str(timeDomainScale.MidSamp,'%8.0f'),'Position',[1 2 72 18],...
    'Callback',{@TDLDispSampCallback,samplesPerCode,data,settings.fileType,timeScale,timeDomainScale, GraphPanel, settings.samplingFreq});

    uicontrol('Parent',TDLpanel,'Style','edit','Tag','TDPRdisp',...
    'String',num2str(timeDomainScale.Mid,'%3.5f'),'Position',[73 2 72 18],...
    'Callback',{@TDLDispCallback,samplesPerCode,data,settings.fileType,timeScale,timeDomainScale, GraphPanel, settings.samplingFreq});

    
    %--- Frequency domain plot --------------------------------------------

    scale = histogramFrequencyScale.Mid;
    
    if (settings.fileType==1) %Real Data
        subplot(2,2,1:2);
        pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq/1e6)
    else % I/Q Data
        subplot(3,2,1:2);
        
        [sigspec,freqv]=pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq,'twosided');
        
        plot(([-(freqv(length(freqv)/2:-1:1));freqv(1:length(freqv)/2)])/1e6, ...
            10*log10([sigspec(length(freqv)/2+1:end);
            sigspec(1:length(freqv)/2)]));
    end

    axis tight;
    grid on;
    if (nargin == 1)
        title('Frequency domain plot')
    else
        name = fileNamestr(9:end-7);
        usename = str2num(name);
        Name = datestr(unixtime(usename));
        title(['Frequency domain plot: ' Name]);
    end
    xlabel('Frequency (MHz)'); ylabel('Magnitude');

    %--- Histogram --------------------------------------------------------
    
    if (settings.fileType == 1)
        subplot(2, 2, 4, 'Parent', GraphPanel);
        
        dmax = max(abs(data(1:round(samplesPerCode*histogramFrequencyScale.Mid)))) + 1;
        hist(data(1:round(samplesPerCode*histogramFrequencyScale.Mid)), -dmax+1:dmax-1)
        
        axis tight;     adata = axis;
        axis([-dmax dmax adata(3) adata(4)]);
        grid on;        title ('Histogram');
        xlabel('Bin');  ylabel('Number in bin');
    else
        subplot(3, 2, 6, 'Parent', GraphPanel);
        
        dmax = max(abs(data(1:round(samplesPerCode*histogramFrequencyScale.Mid)))) + 1;
        hist(real(data(1:round(samplesPerCode*histogramFrequencyScale.Mid))), -dmax+1:dmax-1)
        axis tight;     adata = axis;
        axis([-dmax dmax adata(3) adata(4)]);
        grid on;        title ('Histogram (I)');
        xlabel('Bin');  ylabel('Number in bin');

        subplot(3, 2, 5, 'Parent', GraphPanel);
        
        dmax = max(abs(data(1:round(samplesPerCode*histogramFrequencyScale.Mid)))) + 1;
        hist(imag(data(1:round(samplesPerCode*histogramFrequencyScale.Mid))), -dmax+1:dmax-1)
        axis tight;     adata = axis;
        axis([-dmax dmax adata(3) adata(4)]);
        grid on;        title ('Histogram (Q)');
        xlabel('Bin');  ylabel('Number in bin');

    end

%     [a,b] = regexp(D.name,[logname,'(_DETECT_|_AUTO_)(.)*.IF.bin$'],'start','tokens'); %same thing as before but different files and folders
%     c = regexp(D.name,'(.)*.AGC.bin$','tokens');
%     if(~isempty(a))
%          date = str2double(b{1}{2}); % makes the unix time stamp the date        
%          namefile = [logname,'_FrequencyDomain_',num2str(date)]; %names the file for automatically saved data (23 hours)
%          if(exist([out_folder,'/',namefile,'.jpg'],'file'))
%                  fprintf('EXISTS\n');
%          else
%              saveas(fh,[out_folder,'/',namefile,'.jpg']);
%              close(fh);
%              fprintf('SAVED\n')
%          end
%     end 
%saveas(fh,[out_folder,'/','FrequencyDomain_', str2double(date),'.jpg']); %NEED THIS FIGURED OUT
close(fh);
%fprintf('SAVED\n')

    %--- Sliders ----------------------------------------------------------
    
    %Histogram/Frequency Plot Length Panel
    HFLpanel = uipanel('Title','Histogram/Frequency Domain Length (samples), (ms)','FontSize',8,...
        'Position',[.505 0 .495 .0575], 'BackgroundColor',[.7 .7 .7]);

    %Position in File Panel
    positionPanel = uipanel('Title','Position in File (samples), (s)',...
        'FontSize',8,'Position',[0 .0575 1 .0575], 'BackgroundColor',[.7 .7 .7]);
    
    %Histogram/Frequency Plot Length Slider/Display
    uicontrol('Parent',HFLpanel,'Style','slider','Tag','HFLslid',...
    'Max',histogramFrequencyScale.Max,'Min',histogramFrequencyScale.Min,'Value',histogramFrequencyScale.Mid,...
    'SliderStep',[0.0217391304 0.10],'Position',[147 2 294 18],...
    'Callback',{@HFLSliderCallback,samplesPerCode,data,settings,GraphPanel});

    uicontrol('Parent',HFLpanel,'Style','edit','Tag','HFLdispSamp',...
    'String',num2str(histogramFrequencyScale.MidSamp,'%8.0f'),'Position',[1 2 72 18],...
    'Callback',{@HFLDispSampCallback,samplesPerCode,data,settings,histogramFrequencyScale, GraphPanel});

    uicontrol('Parent',HFLpanel,'Style','edit','Tag','HFLdisp',...
    'String',num2str(histogramFrequencyScale.Mid,'%3.0f'),'Position',[73 2 72 18],...
    'Callback',{@HFLDispCallback,samplesPerCode,data,settings,histogramFrequencyScale, GraphPanel});

    %Position in File Slider/Display
    uicontrol('Parent',positionPanel,'Style','slider','Tag','positionSlid',...
    'Max',positionScale.Max,'Min',positionScale.Min,'Value',positionScale.Mid,...
    'SliderStep',[0.0001 0.05],'Position',[253 2 643 18],...
    'Callback',{@positionSlidCallback,settings});
    
    uicontrol('Parent',positionPanel,'Style','edit','Tag','positionDisp',...
    'String',num2str(positionScale.Mid,'%12.0f'),'Position',[1 2 125 18],...
    'Callback',{@positionDispCallback,settings,positionScale});

    uicontrol('Parent',positionPanel,'Style','edit','Tag','positionDispMs',...
    'String',num2str(positionScaleMs.Mid,'%8.4f'),'Position',[127 2 125 18],...
    'Callback',{@positionDispMsCallback,settings,positionScaleMs});

else
    %=== Error while opening the data file ================================
    error('Unable to read file %s: %s.', fileNamestr, message);
end % if (fid > 0)

%% Callback Functions======================================================

%%Callback function to adjust the time window using sliders
function TDLSliderCallback(~,~,samplesPerCode,data,fileType,timeScale, GraphPanel,samplingFreq)
    
    global TDLScale;

    scale = get(findobj(gcf,'Tag','TDPRslid'),'Value');
    
    set(findobj(gcf,'Tag','TDPRdisp'),'String',num2str(scale,'%6.5f'));
    set(findobj(gcf,'Tag','TDPRdispSamp'),'String',num2str(floor(scale*1/1000*(samplingFreq))));
    
    TDLScale = samplesPerCode*scale;
    
    if (fileType==1)
        
        subplot(2, 2, 3, 'Parent', GraphPanel);
        plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
            data(1:round(samplesPerCode*scale)));

        axis tight;    grid on;
        title ('Time domain plot');
        xlabel('Time (ms)'); ylabel('Amplitude');
        
    elseif (fileType==2)
       
        subplot(3, 2, 4, 'Parent', GraphPanel);
        plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
            real(data(1:round(samplesPerCode*scale))));
        
        axis tight;    grid on;
        title ('Time domain plot');
        xlabel('Time (ms)'); ylabel('Amplitude');
        
        subplot(3, 2, 3, 'Parent', GraphPanel);
        plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
            imag(data(1:round(samplesPerCode*scale))));
        
        axis tight;    grid on;
        title ('Time domain plot');
        xlabel('Time (ms)'); ylabel('Amplitude');
    end
    
%%Callback function to adjust the time window using text boxes
function TDLDispSampCallback(~,~,samplesPerCode,data,fileType,timeScale,timeDomainScale, GraphPanel,samplingFreq)

    global TDLScale;

    sampScale = str2num(get(findobj(gcf,'Tag','TDPRdispSamp'),'String'));
    
    if (isempty(sampScale))
        errordlg('Please enter a numeric value!');
    elseif ((sampScale<timeDomainScale.MinSamp)||sampScale>timeDomainScale.MaxSamp)
        errordlg(['Please enter a value between ',num2str(timeDomainScale.MinSamp),...
            ' and ',num2str(timeDomainScale.MaxSamp)'',' !']);
    else
        scale = 1000 * (samplingFreq)^(-1) * sampScale;
        
        TDLScale = samplesPerCode*scale;
        
        set(findobj(gcf,'Tag','TDPRslid'),'Value',scale);
        set(findobj(gcf,'Tag','TDPRdisp'),'String',num2str(scale,'%3.5f'));
        
        if (fileType==1)

            subplot(2, 2, 3, 'Parent', GraphPanel);
            plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
                data(1:round(samplesPerCode*scale)));

            axis tight;    grid on;
            title ('Time domain plot');
            xlabel('Time (ms)'); ylabel('Amplitude');

        elseif (fileType==2)

            subplot(3, 2, 4, 'Parent', GraphPanel);
            plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
                real(data(1:round(samplesPerCode*scale))));

            axis tight;    grid on;
            title ('Time domain plot');
            xlabel('Time (ms)'); ylabel('Amplitude');

            subplot(3, 2, 3, 'Parent', GraphPanel);
            plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
                imag(data(1:round(samplesPerCode*scale))));

            axis tight;    grid on;
            title ('Time domain plot');
            xlabel('Time (ms)'); ylabel('Amplitude');
        end
    end

function TDLDispCallback(~,~,samplesPerCode,data,fileType,timeScale,timeDomainScale,GraphPanel,samplingFreq)

    global TDLScale;

    scale = str2num(get(findobj(gcf,'Tag','TDPRdisp'),'String'));
    
    if (isempty(scale))
        errordlg('Please enter a numeric value!');
    elseif ((scale<timeDomainScale.Min)||scale>timeDomainScale.Max)
        errordlg(['Please enter a value between ',num2str(timeDomainScale.Min),...
            ' and ',num2str(timeDomainScale.Max)'',' !']);
    else
        set(findobj(gcf,'Tag','TDPRslid'),'Value',scale);
        set(findobj(gcf,'Tag','TDPRdispSamp'),'String',num2str(floor(scale*1/1000*(samplingFreq))));

        TDLScale = samplesPerCode*scale;
        
        if (fileType==1)

            subplot(2, 2, 3, 'Parent', GraphPanel);
            plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
                data(1:round(samplesPerCode*scale)));

            axis tight;    grid on;
            title ('Time domain plot');
            xlabel('Time (ms)'); ylabel('Amplitude');

        elseif (fileType==2)

            subplot(3, 2, 4, 'Parent', GraphPanel);
            plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
                real(data(1:round(samplesPerCode*scale))));

            axis tight;    grid on;
            title ('Time domain plot');
            xlabel('Time (ms)'); ylabel('Amplitude');

            subplot(3, 2, 3, 'Parent', GraphPanel);
            plot(1000 * timeScale(1:round(samplesPerCode*scale)), ...
                imag(data(1:round(samplesPerCode*scale))));

            axis tight;    grid on;
            title ('Time domain plot');
            xlabel('Time (ms)'); ylabel('Amplitude');
        end
    end

    
function HFLSliderCallback(~,~,samplesPerCode,data,settings,GraphPanel)

    global HFLScale;

    scale = ceil(get(findobj(gcf,'Tag','HFLslid'),'Value'));

    HFLScale = scale*samplesPerCode;
    
    set(findobj(gcf,'Tag','HFLdispSamp'),'String',num2str(floor(scale*1/1000*(settings.samplingFreq))));
    set(findobj(gcf,'Tag','HFLdisp'),'String',num2str(scale,'%6.0f'));
        
    if (settings.fileType==1) %Real Data
        subplot(2,2,1:2);
        pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq/1e6)
    else % I/Q Data
        subplot(3,2,1:2);
        [sigspec,freqv]=pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq,'twosided');
        plot(([-(freqv(length(freqv)/2:-1:1));freqv(1:length(freqv)/2)])/1e6, ...
            10*log10([sigspec(length(freqv)/2+1:end);
            sigspec(1:length(freqv)/2)]));
    end
    
    axis tight;
    grid on;
    title ('Frequency domain plot');
    xlabel('Frequency (MHz)'); ylabel('Magnitude');
    
    if (settings.fileType == 1)
        subplot(2, 2, 4, 'Parent', GraphPanel);
        dmax = max(abs(data(1:round(samplesPerCode*scale))))+1;
        hist(data(1:round(samplesPerCode*scale)),  -dmax+1:dmax-1)
        axis tight;     adata = axis;
        axis([-dmax dmax adata(3) adata(4)]);
        grid on;        title ('Histogram');
        xlabel('Bin');  ylabel('Number in bin');
        
    else
        subplot(3, 2, 6, 'Parent', GraphPanel);
        dmax = max(abs(data(1:round(samplesPerCode*scale)))) + 1;
        hist(real(data(1:round(samplesPerCode*scale))), -dmax+1:dmax-1)
        axis tight;     adata = axis;
        axis([-dmax dmax adata(3) adata(4)]);
        grid on;        title ('Histogram (I)');
        xlabel('Bin');  ylabel('Number in bin');
        
        subplot(3, 2, 5, 'Parent', GraphPanel);
        dmax = max(abs(data(1:round(samplesPerCode*scale)))) + 1;
        hist(imag(data(1:round(samplesPerCode*scale))),  -dmax+1:dmax-1)
        axis tight;     adata = axis;
        axis([-dmax dmax adata(3) adata(4)]);
        grid on;        title ('Histogram (Q)');
        xlabel('Bin');  ylabel('Number in bin');
    end

function HFLDispSampCallback(~,~,samplesPerCode,data,settings,histogramFrequencyScale,GraphPanel)

    global HFLScale;

    sampScale = str2num(get(findobj(gcf,'Tag','HFLdispSamp'),'String'));
    
    if (isempty(sampScale))
        errordlg('Please enter a numeric value!');
    elseif ((sampScale<histogramFrequencyScale.MinSamp)||sampScale>histogramFrequencyScale.MaxSamp)
        errordlg(['Please enter a value between ',num2str(histogramFrequencyScale.MinSamp),...
        ' and ',num2str(histogramFrequencyScale.MaxSamp)'',' !'])
    else
        scale = 1000 * (settings.samplingFreq)^(-1) * sampScale;
        
        HFLScale = scale*samplesPerCode;
        
        set(findobj(gcf,'Tag','HFLslid'),'Value',scale);
        set(findobj(gcf,'Tag','HFLdisp'),'String',scale);
        
        if (settings.fileType==1) %Real Data
            subplot(2,2,1:2);
            pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq/1e6)
        else % I/Q Data
            subplot(3,2,1:2);
            [sigspec,freqv]=pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq,'twosided');
            plot(([-(freqv(length(freqv)/2:-1:1));freqv(1:length(freqv)/2)])/1e6, ...
                10*log10([sigspec(length(freqv)/2+1:end);
                sigspec(1:length(freqv)/2)]));
        end

        axis tight;
        grid on;
        title ('Frequency domain plot');
        xlabel('Frequency (MHz)'); ylabel('Magnitude');

        if (settings.fileType == 1)
            subplot(2, 2, 4, 'Parent', GraphPanel);
            dmax = max(abs(data(1:round(samplesPerCode*scale))))+1;
            hist(data(1:round(samplesPerCode*scale)), -dmax+1:dmax-1)
            

            axis tight;     adata = axis;
            axis([-dmax dmax adata(3) adata(4)]);
            grid on;        title ('Histogram');
            xlabel('Bin');  ylabel('Number in bin');
        else
            subplot(3, 2, 5, 'Parent', GraphPanel);
            dmax = max(abs(data(1:round(samplesPerCode*scale)))) + 1;
            hist(imag(data(1:round(samplesPerCode*scale))), -dmax+1:dmax-1)
            axis tight;     adata = axis;
            axis([-dmax dmax adata(3) adata(4)]);
            grid on;        title ('Histogram (Q)');
            xlabel('Bin');  ylabel('Number in bin');
            
            subplot(3, 2, 6, 'Parent', GraphPanel);
            dmax = max(abs(data(1:round(samplesPerCode*scale)))) + 1;
            hist(real(data(1:round(samplesPerCode*scale))), -dmax+1:dmax-1)
            axis tight;     adata = axis;
            axis([-dmax dmax adata(3) adata(4)]);
            grid on;        title ('Histogram (I)');
            xlabel('Bin');  ylabel('Number in bin');
        end
    end
    
function HFLDispCallback(~,~,samplesPerCode,data,settings,histogramFrequencyScale,GraphPanel)
    
    global HFLScale;

    scale = str2num(get(findobj(gcf,'Tag','HFLdisp'),'String'));
    
    if (isempty(scale))
        errordlg('Please enter a numeric value!');
    elseif ((scale<histogramFrequencyScale.Min)||scale>histogramFrequencyScale.Max)
        errordlg(['Please enter a value between ',num2str(histogramFrequencyScale.Min),...
            ' and ',num2str(histogramFrequencyScale.Max)'',' !'])
    else
        HFLScale = scale*samplesPerCode;
        
        set(findobj(gcf,'Tag','HFLdispSamp'),'String',num2str(floor(scale*1/1000*(settings.samplingFreq))));
        set(findobj(gcf,'Tag','HFLslid'),'Value',scale);
        
        if (settings.fileType==1) %Real Data
            subplot(2,2,1:2);
            pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq/1e6)
        else % I/Q Data
            subplot(3,2,1:2);
            [sigspec,freqv]=pwelch(data(1:round(samplesPerCode*scale)), 32758, 2048, 16368, settings.samplingFreq,'twosided');
            plot(([-(freqv(length(freqv)/2:-1:1));freqv(1:length(freqv)/2)])/1e6, ...
                10*log10([sigspec(length(freqv)/2+1:end);
                sigspec(1:length(freqv)/2)]));
        end

        axis tight;
        grid on;
        title ('Frequency domain plot');
        xlabel('Frequency (MHz)'); ylabel('Magnitude');

        if (settings.fileType == 1)
            subplot(2, 2, 4, 'Parent', GraphPanel);
            dmax = max(abs(data(1:round(samplesPerCode*scale))))+1;
            hist(data(1:round(samplesPerCode*scale)), -dmax+1:dmax-1)
            

            axis tight;     adata = axis;
            axis([-dmax dmax adata(3) adata(4)]);
            grid on;        title ('Histogram');
            xlabel('Bin');  ylabel('Number in bin');
        else
            subplot(3, 2, 5, 'Parent', GraphPanel);
            dmax = max(abs(data(1:round(samplesPerCode*scale)))) + 1;
            hist(imag(data(1:round(samplesPerCode*scale))), -dmax+1:dmax-1)
            axis tight;     adata = axis;
            axis([-dmax dmax adata(3) adata(4)]);
            grid on;        title ('Histogram (Q)');
            xlabel('Bin');  ylabel('Number in bin');
            
            subplot(3, 2, 6, 'Parent', GraphPanel);
            dmax = max(abs(data(1:round(samplesPerCode*scale)))) + 1;
            hist(real(data(1:round(samplesPerCode*scale))), -dmax+1:dmax-1)
            axis tight;     adata = axis;
            axis([-dmax dmax adata(3) adata(4)]);
            grid on;        title ('Histogram (I)');
            xlabel('Bin');  ylabel('Number in bin');
        end
    end
    
function positionDispCallback(~,~,settings,positionScale)
    
    scale = str2num(get(findobj(gcf,'Tag','positionDisp'),'String'));
    
    if (isempty(scale))
        errordlg('Please enter a numeric value!');
    elseif ((scale<positionScale.Min)||scale>positionScale.Max)
        errordlg(['Please enter a value between ',num2str(positionScale.Min),...
            ' and ',num2str(positionScale.Max)'',' !'])
    else
        settings.skipNumberOfSamples = scale;
    
        probeData(settings);
    end
    
function positionDispMsCallback(~,~,settings,positionScaleMs)
    
    scale =  str2num((get(findobj(gcf,'Tag','positionDispMs'),'String')));
    
    if (isempty(scale))
        errordlg('Please enter a numeric value!');
    elseif ((scale<positionScaleMs.Min)||scale>positionScaleMs.Max)
        errordlg(['Please enter a value between ',num2str(positionScaleMs.Min),...
            ' and ',num2str(positionScaleMs.Max)'',' !'])
    else
        sampleScale = settings.samplingFreq*scale;
        
        settings.skipNumberOfSamples = sampleScale;
    
        probeData(settings);
    end
        
function positionSlidCallback(~,~,settings)

    scale = ceil(get(findobj(gcf,'Tag','positionSlid'),'Value'));
    
    settings.skipNumberOfSamples = scale;
    
    probeData(settings);

%     D = dir(folder); %list directory of folder
%     nf = numel(D); %number of elements in folder
%     for j = 3:nf %3: number of elements in folder
%         [a,b] = regexp(D(j).name,[logname,'(_DETECT_|_AUTO_)(.)*.AGC.bin$'],'start','tokens'); %same thing as before but different files and folders
%         if(~isempty(a))
%             date = str2double(b{1}{2}); % makes the unix time stamp the date
%             
%             sampling_freq = 8.183800e6;
%             trig_value = 0;
%             
%             c = regexp(D(j).name,'(.)*.AGC.bin$','tokens'); %checks for D(j).name match in folder
%             
%             %get AGC values of this file
%             fid = fopen([folder,'/',D(j).name],'rb'); %binary conversion when opening
%             data = fread(fid,'uint32'); %read binary data
%             fclose(fid);
%             
%             %de-entrelace data
%             stt = data(2:2:end); %time
%             sagc = data(1:2:end)*3.3/4096; %AG
%         end
%     end
%     UTC_time = datenum([1970 1 1 0 0 stt(1)]);
%     titlefig = {logname, ['Unix: ',num2str(stt(1))],['UTC: ',datestr(UTC_time)]}; %e_fig = {logname,['First Unix Timestamp : ',num2str(stt(1))],['First UTC Time : ',datestr(UTC_time)]};
%     title ('Parent',titlefig,'Units','normalized','Position',[1.0 1.2],'VerticalAlignment','middle','FontSize',12);
