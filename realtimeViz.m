% Assuming unpacked continuous IF data
calib_file = 'calibration.mat';
load(calib_file); % Loads in steps_agc, & steps_atten from calibration.mat
addpaths;

folder = '/home/dma/sige_code';
lenLog = 4;
D = dir(folder);
nf = numel(D);
for i = 3:nf
    a(i) = D(i).datenum;
end

[val,ind] = max(a);

name = D(ind).name;

AGCorIF = name(end-4);

if strcmp(AGCorIF,'C')
    othername = [name(1:lenLog+29) 'IF.bin'];
    datafileAGC = [folder '/' name];
    datafileIF = [folder '/' othername];
elseif strcmp(AGCorIF,'F')
    othername = [name(1:lenLog+29) 'AGC.bin'];
    datafileAGC = [folder '/' othername];
    datafileIF = [folder '/' name];
end

isCont = name(lenLog+2:lenLog+5);
if ~strcmp(isCont,'CONT')
    error('Please have continuous IF data.')
end

isUnpacked = name(lenLog+7);
if ~strcmp(isUnpacked,'U')
    error('Please have unpacked IF data.')
end

% Filenames
% datafileAGC = '/home/gnss/sige_code/data/TEST_AGC_2017-05-05T16-37-58.AGC.bin';
% datafileIF = '/home/gnss/sige_code/data/TEST_IF_2017-05-05T16-37-58.IF.bin';
% Open files and move to end of file for reading
fidA = fopen(datafileAGC);
fidIF = fopen(datafileIF);
fseek(fidA,0,1);
fseek(fidIF,0,1);

n = 3; % How often to update in seconds, SHOULD BE AT LEAST 3 sec (for now)
m = 10; % How much previous data to visualize in seconds
% Pauses for n seconds, starts with new data created once function starts,
% meaning no previous data is shown
pause(n);
ii = 1;
while(1)
    % Time of start
    tic;
    % Gather data of last n seconds
    AGCdata = fread(fidA, 'uint32');
    stt = AGCdata(2:2:end); % time
    stt = interpTime(stt);
    sagc = AGCdata(1:2:end)*3.3/4096;
    % Gather spectrum data
    [F,T,P] = spectroRealTime(fidIF,sagc,steps_agc,steps_atten);
    
    %% Plot AGC
    if ii == 1
        subplot(2,1,1)
        plot(stt,sagc,'g.')
        grid on
        title('Real Time AGC Visualization')
        start_time = stt(1);
        end_time = stt(end);
        stt_1 = stt;
        sagc_1 = sagc;
    end
    if ii == 2
        subplot(2,1,1)
        hold on
        plot(stt,sagc,'g.')
        plot(stt_1,sagc_1,'g.')
        grid on
        title('Real Time AGC Visualization')
        start_time = stt_1(1);
        end_time = stt(end);
        stt_2 = stt_1;
        sagc_2 = sagc_1;
        stt_1 = stt;
        sagc_1 = sagc;
    end
    if ii > 2 && (stt(end) - stt_2(1)) < m
        subplot(2,1,1)
        hold on
        plot(stt,sagc,'g.')
        plot(stt_1,sagc_1,'g.')
        plot(stt_2,sagc_2,'g.')
        grid on
        title('Real Time AGC Visualization')
        start_time = stt_2(1);
        end_time = stt(end);
        stt_2 = [stt_2;stt_1];
        sagc_2 = [sagc_2;sagc_1];
        stt_1 = stt;
        sagc_1 = sagc;
    end
    if ii > 2 && (stt(end) - stt_2(1)) >= m
        subplot(2,1,1)
        hold on
        plot(stt,sagc,'g.')
        plot(stt_1,sagc_1,'g.')
        plot(stt_2,sagc_2,'g.')
        grid on
        title('Real Time AGC Visualization')
        start_time = stt(end) - m;
        end_time = stt(end);
        stt_2 = [stt_2;stt_1];
        sagc_2 = [sagc_2;sagc_1];
        stt_1 = stt;
        sagc_1 = sagc;
    end
    
    %% Scale the X-Axis
    % Check if the x ticks are supposed to be every hour
    [tick_loc,tick_label] = scale_x_axis(start_time,end_time);
    xlim([start_time, end_time]);
    ylim([0 1.5])
    
    tick_label = -(end_time - tick_loc);
    tick_label(tick_label == -0) = 0;
    
    
    set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
    set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
    ylabel('AGC Value [V]');
    xlabel('Seconds Ago [s]');
    
    %% Spectrum Plot
    h_spectr = subplot(2,1,2);
    h_spectr_plot = pcolor(h_spectr,(F+1575.42e6 - 38.4e3)*1e-6,T,10*log10(P));
    set(h_spectr_plot,'LineStyle','none'); % No line
    colormap(h_spectr,jet(1024));
    colormark = 10*log10(P);
    maxcolor = max(max(colormark));
    mincolor = min(min(colormark));
    set(h_spectr,'CLim',[mincolor maxcolor]); % Color spectrum
    set(h_spectr,'FontSize',12)
    xlabel('Frequency [MHz]')
    ylabel('Time [s]')
    
    %% Pause until n seconds
    if toc < n
        pause(n-toc)
    end
    ii = ii + 1;
end

