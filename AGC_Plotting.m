function [plot_fid, plotted_time, plotted_agc] = AGC_Plotting(start_time...
    ,end_time,directory,file_name,thresh,pts_under_thrsh)
% input:
%   start_time:       start time for plotting (unix timestamp)
%   end_time:         end time for plotting (unix timestamp)
%   points_per_day:   number of points to be plotted in one day
%   directory:        directory where the AGC data files are located
%   file_name:        search name for AGC data files (ex.
%                       ['/*' logname '_AGC*AGC.bin'])
%   AGC_threshold:    threshold of AGC data that defines when the reciever
%                       detects jammers or spoofers
% output:
%   plot of the AGC data between the start and end times
%   fid:                the id for the figure so it can be saved or
%                       manipulated
%   plotted_time:       vector of the plotted times in unix time
%   plotted_agc:        vector of the plotted agc data 

% Initialize outputs
plotted_time = [];
plotted_agc = [];
plotted_EventTime = [];
plotted_EventAGC = [];

%% Find Files in Time Range
rawData = dir(strcat(directory,file_name));% Lists files that match format
% Get the unix times from the file names
fileNames = {rawData.name}; % Cell arrays with names
% Match date
fileDate_str = regexp(fileNames, ['_AGC_(.)*.AGC.bin$'], 'tokens'); 
fileDate_str = [fileDate_str{:}]; % Concatenate all cells into one string
if(isempty(fileNames)) % No files found, return
    disp(['No AGC files were found in the directory '...
        'that matched the file name']);
    plot_fid = -1;
    return;
end
% Change to strings then to unixtime stamps
for i = 1:length(fileDate_str)
    string = [fileDate_str{i}];
    string2 = string{:};
    fileDate(i) = conv_to_unixtime(string2);
end
% Make sure the dates are in ascending order
[fileDate, idx] = sort(fileDate); % Shows fileDate and index organized
fileNames = fileNames(idx); % Reorganize files in same order as fileDate
% All files after start_date and before end_time are true
file_index =  (fileDate + 86399 >= start_time) & (fileDate < end_time); 
fileNames = fileNames(file_index); % Only files after start and before end
if(isempty(fileNames)) % Checks if empty
    disp('No data was found in the time range');
    plot_fid = -1;
    return;
end
fileDate = fileDate(file_index); % Now only dates in time range

%% Plot files in Time Range
% Open figure
plot_fid = figure; % plot_fid is plot handle
% Iterate through the files that are potentially in the time range and
% plot them
for ii = 1:length(fileNames)
    fid = fopen(char(strcat(directory, '/', fileNames(ii))));
    data = fread(fid, 'uint32'); % read binary file 4 bytes at a time
    fclose(fid);
    time = data(2:2:end); % Sets time as every other value, starting at 2
    % Deinterlace AGC data
    % ADC has 3.3V range and 12 bits give 4096 (2^12) discrete steps
    agc = data(1:2:end)*3.3/4096; 
    clear 'data'
    % Find times that are in the time range
    time_index = find(time >= start_time & time <= end_time);
    time = time(time_index); % Sets time to only the time in time range

    if (~isempty(time)) % If not empty (expected), but could be empty
        time = interpTime(time);
        % Creates array of trigger points that will be made red in future
        agc = agc(time_index); % Set agc to corresponding agc in time range
        k = 1;
        % Checks for trigger events
        for i = 1:length(agc)-pts_under_thrsh
            if agc(i:i+pts_under_thrsh-1) < thresh
                EventAGC(k) = agc(i);
                EventTime(k) = time(i);
                k = k + 1;
            end
        end
        % Plot
        plotted_time = [plotted_time; time];
        plotted_agc = [plotted_agc; agc];
        
        % Check if there was no data plotted and return
        if isempty(plotted_time)
            disp('No data was found for the time range specified');
            close(plot_fid);
            plot_fid = -1;
            return;
        end
        % Plot
        hold on
        smootheda = smooth(plotted_agc,20);
        plot(gca, plotted_time, smootheda, 'go','MarkerSize',6,...
            'MarkerFaceColor','g');
%         plot(gca, plotted_time, plotted_agc, 'go','MarkerSize',6,...
%             'MarkerFaceColor','g');
        if exist('EventTime','var')
            plotted_EventTime = [plotted_EventTime; EventTime];
            plotted_EventAGC = [plotted_EventAGC; EventAGC];
            smoothed = smooth(plotted_EventAGC,20);
            plot(gca,plotted_EventTime,smoothed,'ro','MarkerSize',6,...
                'MarkerFaceColor','r');
%             plot(gca,plotted_EventTime,plotted_EventAGC,'ro','MarkerSize',6,...
%                 'MarkerFaceColor','r');
        end
        hold off
    end
end

%% Scale the X-Axis
% Check if the x ticks are supposed to be every hour
[tick_loc,tick_label] = scale_x_axis(start_time,end_time);

%% Set Plot Parameters
% Set x axis limits
xlim([min(plotted_time)-2, max(plotted_time)+2]);
ylim([0.1 1.35])
set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
ylabel('AGC Value [V]');
xlabel('UTC Time');
end
