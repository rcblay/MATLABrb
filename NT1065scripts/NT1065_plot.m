%function NT1065_plot(filename,Channels,timerange,TimeStart,Day)

%% Read in AGC Data
filenameAGC = '/home/dma/Documents/regdump.bin';
Channels = 1;
timerange = [79.864 79.89177777];
TimeStart = 0;
Day = 0;
[time,agc] = parseFileAGC2(filenameAGC,Channels,timerange,TimeStart,Day);
time = (time - time(1))*3600;
agc = agc(:,1);
time = time(:,1);

%% Unpack NT1065 Data
filename1 = '/home/dma/Documents/NT1065_IF.bin';
timeAfterStart = timerange(1)*3600;
desiredSec = (timerange(2)-timerange(1))*3600;
sampleFreq = 6.625e6;
BytesAfterStart = sampleFreq*timeAfterStart;
BytesToRead = sampleFreq*floor(desiredSec);
fid = fopen(filename1,'rb');
fseek(fid,BytesAfterStart,-1);
A = fread(fid,BytesToRead,'ubit8');
fid2 = fopen('temp1.bin','wb');
fwrite(fid2,A);

filename_in = 'temp1.bin';
filename_out = 'temp2.bin';
L1L2 = 1; % Specifies L1
unpack_NT1065(filename_in,filename_out,L1L2);

%% Track NT1065 IF data
filenameIF = filename_out;
[CNo_val,CNo_ind] = findTrackResultsNT1065(filenameIF,desiredSec);

%% Load in calib_file
calib_file = 'calibration.mat';
load(calib_file);

%% Do Spectrum Plot for NT1065 data
nf = 1024;
sampling_freq = 6.625e6;
unpacked_coeff = 2;
filename_in = 'temp2.bin';

[F,T,P] = spectro(filename_in,nf,agc,steps_atten,steps_agc,sampling_freq...
    ,unpacked_coeff);

%% Plot
% Plot the spectrogram and the AGC
h_fig = figure(42); % Assigns figure handle
set(h_fig,'Renderer','painters'); % Sorts graphic objects
set(h_fig,'Units','pixels'); % Sets units to be pixels
% Defines border distances and dimensions
set(h_fig,'units','normalized','outerposition',[0 0 1 1])
% Spectro axis sets location inside a 1x1 square and font
h_spectr = axes('Position',[0.1 0.1 0.4 0.70],...
    'FontSize',8);
% AGC axes sets location inside a 1x1 square
h_agc_CNo = axes('Position', [0.55 0.1 0.30 0.70]);
                    
% Create graphs with x-axis on both top and bottom
[h_agc_CNo, ~, ~] = plotxx(agc,time,CNo_val,CNo_ind/1000,...
    {'AGC value [V]', 'C/No (dB-Hz)'}, {'',''});
% Above: AGC, VSM value, VSM index/1000, Label: AGC
% value, Label: Hz, nothing on y axes
% Set axis properties
set(h_agc_CNo(1),'Position',[0.55 0.1 0.30 0.70]...
    ,'yticklabel',[])
set(h_agc_CNo(2),'Position',[0.55 0.1 0.30 0.70]...
    ,'yticklabel', [], 'YColor', 'r')
set(h_agc_CNo(1),'FontSize',16)
set(h_agc_CNo(2),'FontSize',16)
xlim(h_agc_CNo(1), [0.0 50]);
xlim(h_agc_CNo(2), [25 55]);

h_spectr_plot = pcolor(h_spectr,F*1e-6,T,10*log10(P));
set(h_spectr_plot,'LineStyle','none'); % No line
% Do a bunch of fancy settings to make plot look nice
ylabel(h_spectr,'Time [s]','FontSize',16); % Time
xlabel(h_spectr,'Frequency [MHz]','FontSize',16); % Freq
% Title
title_fig = {'NT1065',['Channel(s) : ',...
    num2str(Channels)],['Time Start : ',...
    datestr(TimeStart)]}; % 2 times
title ('Parent',h_spectr,title_fig,'Units','normalized',...
    'Position',[1.0 1.2],'VerticalAlignment','middle',...
    'FontSize',12);
% Colorbar
h_colorbar = colorbar('peer',h_spectr,'NorthOutside');
set(h_colorbar,'Position',[0.1 0.8 0.4 0.01]);
set(h_colorbar,'FontSize',16);
set(h_spectr,'FontSize',16);
colormap(jet(1024));
colormark = 10*log10(P);
maxcolor = max(max(colormark));
mincolor = min(min(colormark));
set(h_spectr,'CLim',[mincolor maxcolor]); % Color spectrum

%saveas(h_fig,[out_folder,'/',namefile,'.jpg']);
%close(h_fig);