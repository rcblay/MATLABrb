% AGCplotall simply plots all AGC files in a folder

%% Housekeeping
clearvars
close all
clc

%% Adds Folders to Path
addpaths;

%% Sets parameters
% Make sure to change initSettings if needed
folder = '/mnt/admin/Brandon_Idaho/Night4/SiGe';
lenLog = 5;

D = dir(folder);
nf = numel(D); % Number of files/directories in folder is set to nf
for i = 3:nf
    file = D(i).name;
    out_folder = [folder,'/figures'];
    logname = file(1:lenLog); %'rec'
    titlename = logname;
    fontsize = 18;
    localUTC = 18;
    Ahead_Behind = 0; % Ahead of UTC = 1 (Korea), Behind UTC = 0 (Boulder)
    
    %% Trigger Settings
    thresh = 0.001; % Voltage threshold
    pts_under_thrsh = 5; % # of pts under threshold that constitutes a trigger
    
    %% Check for Existing Variables/Out Folder
    % If the folder out_folder doesn't exist (checks only for folders)
    if ~exist(out_folder,'dir')
        mkdir(out_folder); % Make new folder called out_folder
    end
    
    %% Plot
    if Ahead_Behind == 0 % Behind
        offset = [', (Local: UTC-',num2str(24-localUTC),')'];
    else % Ahead
        offset = [', (Local: UTC+',num2str(localUTC),')'];
    end
    out = char(file); % Changes from cell to string
    datestring = out((10+lenLog):end-8);
    filename = conv_to_unixtime(datestring);
    start_time = filename; % Day collection began
    plotdate = unixtime(filename); % Changes to date vector
    strdate = datestr(plotdate,0);
    strdate(strdate == ' ') = '_';
    strdate(strdate == ':') = '-';
    FN = [logname,'_DailyAGC_',strdate];
    % Find end_time by looking at last time entry in file
    fid = fopen(char([folder, '/', file]));
    data = fread(fid, 'uint32'); % read bin file 4 bytes at a time
    time = data(2:2:end);
    % Deinterlace AGC data
    % ADC has 3.3V range and 12 bits give 4096 (2^12) discrete steps
    agc = data(1:2:end)*3.3/4096;
    clear 'data'
    end_time = time(end); % Day collection ended
    time = interpTime(time);
    
    plot_fid = figure; % plot_fid is plot handle
    
    k = 1;
    % Checks for trigger events
    for i = 1:length(agc)-pts_under_thrsh
        if agc(i:i+pts_under_thrsh-1) < thresh
            EventAGC(k) = agc(i);
            EventTime(k) = time(i);
            k = k + 1;
        end
    end
    hold on
    plot(gca, time, agc, 'go','MarkerSize',6,...
        'MarkerFaceColor','g');
    if exist('EventTime','var')
        plot(gca,EventTime,EventAGC,'ro','MarkerSize',6,...
            'MarkerFaceColor','r');
    end
    hold off
    
    %% Scale the X-Axis
    % Check if the x ticks are supposed to be every hour
    [tick_loc,tick_label] = scale_x_axis(start_time,end_time);
    
    %% Set Plot Parameters
    % Set x axis limits
    xlim([min(time)-2, max(time)+2]);
    ylim([0.01 1.35])
    set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
    set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
    ylabel('AGC Value [V]');
    
    if exist('titlename','var')
        title(gca, [titlename ' AGC Data (from ', ...
            datestr(unixtime(start_time),0), ' to ', ...
            datestr(unixtime(end_time),0), ' [UTC])']);grid;
    else
        title(gca, [logname ' AGC Data (from ', ...
            datestr(unixtime(start_time),0), ' to ', ...
            datestr(unixtime(end_time),0), ' [UTC])']);grid;
    end
    
    xlabel(['UTC Time',offset])
    %set(findall(gcf,'-property','FontSize'),'FontSize',16)
    set(plot_fid,'units','normalized','outerposition',[0 0 1 1])
    set(gca,'FontSize',fontsize)
    saveas(plot_fid, [out_folder '/' logname '_DailyAGC_', ...
        strdate, '.fig']);
    saveas(plot_fid, [out_folder '/' logname '_DailyAGC_', ...
        strdate, '.jpg']);
    close(plot_fid);
end
