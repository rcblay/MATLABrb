function plotSpectrumPlotNT(figNum,stt,sagc,trackResults,channelNr,...
    unpck_filename,sampling_freq,unpacked_coeff,...
    centerfreq,interfreq,offset,out_folder,namefile,logname)
% Plot the combined plot of agc & C/N0 with the spectrum
h_fig = figure(figNum); % Assigns figure handle
set(h_fig,'Renderer','painters'); % Sets units to be pixels
set(h_fig,'Units','pixels'); % Sets units to be pixels
% Defines border distances and dimensions
set(h_fig,'units','normalized','outerposition',[0 0 1 1])
% Spectro axis sets location inside a 1x1 square and font
h_spectr = axes('Position',[0.1 0.1 0.4 0.70],...
    'FontSize',8);
% AGC axes sets location inside a 1x1 square
h_agc_CNo = axes('Position', [0.55 0.1 0.30 0.70]);

%% Plot AGC and C/N0

if(isempty(trackResults))
    plot(sagc,stt-stt(1),'k'); % plot AGC black
    h_agc_CNo = gca;
    set(h_agc_CNo, 'yticklabel', []);
    set(h_agc_CNo,'FontSize',12)
    xlabel('AGC value [dB]'); % Label x-axis
    xlim(h_agc_CNo, [0.0 60]); % Even spaces on x-axis
else
    [h_agc_CNo, ~, ~] = plotxx(sagc,stt-stt(1)...
        ,trackResults(channelNr).CNo.VSMValue,...
        trackResults(channelNr).CNo.VSMIndex/1000,...
        {'AGC value [dB]', 'C/No (dB-Hz)'}, {'',''});
    % Above: AGC, VSM value, VSM index/1000, Label: AGC
    % value, Label: Hz, nothing on y axes
    % Set axis properties
    set(h_agc_CNo(1),'Position',[0.55 0.1 0.30 0.70]...
        ,'yticklabel',[])
    set(h_agc_CNo(2),'Position',[0.55 0.1 0.30 0.70]...
        ,'yticklabel', [], 'YColor', 'r')
    set(h_agc_CNo(1),'FontSize',12)
    set(h_agc_CNo(2),'FontSize',12)
    xlim(h_agc_CNo(1), [0.0 60]);
    xlim(h_agc_CNo(2), [25 55]);
end
%% Spectro
[F,T,P] = spectroNT(unpck_filename,1024,sagc,sampling_freq,unpacked_coeff);

%% 3D plot
figure(figNum+100);
h_spectr_plot3d = mesh((F+centerfreq - interfreq)*1e-6,T,10*log10(P));
xlabel('Frequency [MHz]','FontSize',16)
ylabel('Time [s]','FontSize',16)
zlabel('Power [dB]','FontSize',16)
UTC_time = datenum([1970 1 1 0 0 stt(1)]);
title({logname,['First Unix Timestamp : ',...
    num2str(stt(1))],['First UTC Time : ',...
    datestr(UTC_time,0),offset]});
pause(5);
colormap(jet(1024));
axis tight
saveas(h_spectr_plot3d,[out_folder,'/3Dplot',namefile,'.jpg']);

%% Format 2d spectrogram
h_spectr_plot = pcolor(h_spectr,(F+centerfreq - interfreq)*1e-6,T,10*log10(P));
set(h_spectr_plot,'LineStyle','none'); % No line
% Do a bunch of fancy settings to make plot look nice
ylabel(h_spectr,'Time [s]','FontSize',16); % Time
xlabel(h_spectr,'Frequency [MHz]','FontSize',16); % Freq
% Title
UTC_time = datenum([1970 1 1 0 0 stt(1)]);
% Add local offset
title_fig = {logname,['First Unix Timestamp : ',...
    num2str(stt(1))],['First UTC Time : ',...
    datestr(UTC_time,0),offset]}; % 2 times
title ('Parent',h_spectr,title_fig,'Units','normalized',...
    'Position',[1.0 1.2],'VerticalAlignment','middle',...
    'FontSize',12);
% Colorbar
h_colorbar = colorbar('peer',h_spectr,'NorthOutside');
set(h_colorbar,'Position',[0.1 0.8 0.4 0.01]);
set(h_colorbar,'FontSize',12)
pause(5);
colormap(h_spectr,jet(1024));
colormark = 10*log10(P);
maxcolor = max(max(colormark));
mincolor = min(min(colormark));
set(h_spectr,'CLim',[mincolor maxcolor]); % Color spectrum
set(h_spectr,'FontSize',12)
saveas(h_fig,[out_folder,'/',namefile,'.jpg']);
close(h_fig);
%close(h_spectr_plot3d);
fprintf('SAVED\n');
end