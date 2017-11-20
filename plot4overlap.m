%% Housekeeping
clearvars
close all
clc

%% Adds Folders to Path
addpaths;

%% Sets parameters
% Make sure to change initSettings if needed
folder = '/home/dma/Documents/MATLAB/TDOArb/DHSdata/SiGe_DHS_day2';
file1 = 'DHS_CONT_P5_2017-07-21T06-43-52.AGC_A.bin';
file2 = 'DHS_CONT_P5_2017-07-21T06-52-36.AGC_B.bin';
file3 = 'DHS_CONT_P5_2017-07-21T06-16-59.AGC_C.bin';
file4 = 'DHS_CONT_P5_2017-07-21T06-23-05.AGC_D.bin';
out_folder = [folder,'/figures'];
logname = 'DHS'; %'rec'
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
lenLog = length(logname);

%% Start Time and End Time
start_time = unixtime([2017 7 21 9 17 20]);
end_time = unixtime([2017 7 21 9 31 20]);

strdate = datestr([2017 7 21 9 17 20],0);
strdate(strdate == ' ') = '_';
strdate(strdate == ':') = '-';

fid1 = fopen(char([folder, '/', file1]));
data1 = fread(fid1, 'uint32'); % read bin file 4 bytes at a time
time1 = data1(2:2:end);
% Deinterlace AGC data
% ADC has 3.3V range and 12 bits give 4096 (2^12) discrete steps
agc1 = data1(1:2:end)*3.3/4096;
clear 'data1'
time1 = interpTime(time1);
time_index1 = find(time1 >= start_time & time1 <= end_time);
time1 = time1(time_index1); % Sets time to only the time in time range
agc1 = agc1(time_index1); % Set agc to corresponding agc in time range

fid2 = fopen(char([folder, '/', file2]));
data2 = fread(fid2, 'uint32'); % read bin file 4 bytes at a time
time2 = data2(2:2:end);
% Deinterlace AGC data
% ADC has 3.3V range and 12 bits give 4096 (2^12) discrete steps
agc2 = data2(1:2:end)*3.3/4096;
clear 'data2'
time2 = interpTime(time2);
time_index2 = find(time2 >= start_time & time2 <= end_time);
time2 = time2(time_index2); % Sets time to only the time in time range
agc2 = agc2(time_index2); % Set agc to corresponding agc in time range

fid3 = fopen(char([folder, '/', file3]));
data3 = fread(fid3, 'uint32'); % read bin file 4 bytes at a time
time3 = data3(2:2:end);
% Deinterlace AGC data
% ADC has 3.3V range and 12 bits give 4096 (2^12) discrete steps
agc3 = data3(1:2:end)*3.3/4096;
clear 'data3'
time3 = interpTime(time3);
time_index3 = find(time3 >= start_time & time3 <= end_time);
time3 = time3(time_index3); % Sets time to only the time in time range
agc3 = agc3(time_index3); % Set agc to corresponding agc in time range

fid4 = fopen(char([folder, '/', file4]));
data4 = fread(fid4, 'uint32'); % read bin file 4 bytes at a time
time4 = data4(2:2:end);
% Deinterlace AGC data
% ADC has 3.3V range and 12 bits give 4096 (2^12) discrete steps
agc4 = data4(1:2:end)*3.3/4096;
clear 'data4'
time4 = interpTime(time4);
time_index4 = find(time4 >= start_time & time4 <= end_time);
time4 = time4(time_index4); % Sets time to only the time in time range
agc4 = agc4(time_index4); % Set agc to corresponding agc in time range

%% Plot

plot_fid = figure; % plot_fid is plot handle
hold on
agc1_s = smooth(agc1,200);

index = find(agc1_s > agc1 + 0.002);

agc1(index) = [];
time1(index) = [];

plot(gca, time1, agc1, 'go','MarkerSize',4,...
    'MarkerFaceColor','g');
plot(gca, time2, agc2, 'co','MarkerSize',4,...
    'MarkerFaceColor','c');
plot(gca, time3, agc3, 'ro','MarkerSize',4,...
    'MarkerFaceColor','r');
plot(gca, time4, agc4, 'mo','MarkerSize',4,...
    'MarkerFaceColor','m');
hold off

legend('System A','System B','System C','System D');

%% Scale the X-Axis
% Check if the x ticks are supposed to be every hour
[tick_loc,tick_label] = scale_x_axis(start_time,end_time);

%% Set Plot Parameters
% Set x axis limits
xlim([min(time1)-2, max(time1)+2]);
ylim([0.01 1.35])
set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
ylabel('AGC Value [V]');

xlabel(['UTC Time',offset])
title(gca, [logname ' AGC Data (', ...
    datestr(unixtime(start_time),0), ' to ', ...
    datestr(unixtime(end_time),0), ' [UTC])']);grid;
%set(findall(gcf,'-property','FontSize'),'FontSize',16)
set(plot_fid,'units','normalized','outerposition',[0 0 1 1])
set(gca,'FontSize',24)
saveas(plot_fid, [out_folder '/' logname '_DailyAGC_', ...
    strdate, '.fig']);
saveas(plot_fid, [out_folder '/' logname '_DailyAGC_', ...
    strdate, '.jpg']);
%close(plot_fid);

