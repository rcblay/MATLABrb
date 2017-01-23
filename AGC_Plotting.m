function [plot_fid, plotted_time, plotted_agc] = AGC_Plotting(start_time...
    ,end_time,directory,file_name,x_tick_location,thresh,pts_under_thrsh)
% input:
%   start_time:       start time for plotting (unix timestamp)
%   end_time:         end time for plotting (unix timestamp)
%   points_per_day:   number of points to be plotted in one day
%   directory:        directory where the AGC data files are located
%   file_name:        search name for AGC data files (ex.
%                       /*korea_AGC*AGC.bin')
%   AGC_threshold:    threshold of AGC data that defines when the reciever
%                       detects jammers or spoofers
%   x_tick_location: determines the location for x-axis tick marks.
%                       0=hourly
%                       1=daily
%                       2=weekly
%                       3=monthly
% output:
%   plot of the AGC data between the start and end times
%   fid:                the id for the figure so it can be saved or
%                       manipulated
%   plotted_time:       vector of the plotted times in unix time
%   plotted_agc:        vector of the plotted agc data 

% Initialize outputs
plotted_time = [];
plotted_agc = [];

%% Find Files in Time Range
rawData = dir(strcat(directory,file_name));% Lists files that match format
% Get the unix times from the file names
fileNames = {rawData.name}; % Cell arrays with names
fileDate = regexp(fileNames, '\d{10,10}', 'match'); % Match name and date
fileDate = [fileDate{:}]; % Concatenate all cells into one string
if(isempty(fileNames)) % No files found, return
    disp(['No AGC files were found in the directory '...
        'that matched the file name']);
    plot_fid = -1;
    plot_start_time = -1;
    return;
end
fileDate = cellfun(@str2num,fileDate); % Converts each cell from str to num 
% Make sure the dates are in ascending order
[fileDate, idx] = sort(fileDate); % Shows fileDate and index organized
fileNames = fileNames(idx); % Reorganize files in same order as fileDate
% All files after start_date and before end_time are true
file_index =  (fileDate + 86399 >= start_time) & (fileDate <= end_time); 
fileNames = fileNames(file_index); % Only files after start and before end
if(isempty(fileNames)) % Checks if empty
    disp('No data was found in the time range');
    plot_fid = -1;
    plot_start_time = -1; % Might be unnecessary
    return;
end
fileDate = fileDate(file_index); % Now only dates in time range

%% Plot files in Time Range
% Open figure
plot_fid = figure; % plot_fid is plot handle
% Iterate through the files that are potentially in the time range and
% plot them
for ii = 1:length(fileNames) % Most certainly only length=1
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
        for i = 1:length(agc)-pts_under_thrsh
            if agc(i:i+pts_under_thrsh-1) < thresh
                EventAgc(k) = agc(i);
                EventTime(k) = time(i);
                k = k + 1;
            end
        end
        % Break data into blocks
        tot_time = time(end)-time(1); % Total time
        if (end_time-start_time <= 24*60*60) % If less than/equal a day
            hold on
            plot(gca,time, agc,'go','MarkerSize',6,'MarkerFaceColor','g');
            if exist('EventTime','var')
                plot(gca,EventTime,EventAgc,'ro','MarkerSize',6,...
                    'MarkerFaceColor','r');
            end
            hold off
        else
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
            plot(gca, plotted_time, plotted_agc, 'go','MarkerSize',6,...
                'MarkerFaceColor','g');
            if exist('EventTime','var')
                plot(gca,EventTime,EventAgc,'ro','MarkerSize',6,...
                    'MarkerFaceColor','r');
            end
            hold off
        end
    end
end

%% Scale the X-Axis
% Check if the x ticks are supposed to be every hour

if ~isempty(plotted_time)
    tot_time = plotted_time(end) - plotted_time(1);
end

if x_tick_location == 0
    % Find the first hour in the data
    offset = mod(start_time, 24*60*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    % Create vector of tick_loc and tick_label using temp value and
    % appending it to current vector. tick_loc spread out every two hours
    % if the tot_time is greater than two hours
    if (tot_time <= 86400)
        while tick_loc(end) < time(end)
            % If greater than 2 hours, location is spread out every 2 hours
            if( tot_time > 2*3600 ) 
                temp_tick_loc = temp_tick_loc + (2*60*60);
            else % Otherwise location is every hour
                temp_tick_loc = temp_tick_loc + (60*60);
            end
            % Append to existing vectors
            tick_loc = [tick_loc, temp_tick_loc];
            tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
                'HH:MM')];
        end
    else % If time is greater than a day, same concept as above
        tick_label = datestr(unixtime(tick_loc), 'mmm-dd HH:MM');
        while tick_loc(end) < plotted_time(end)
            if( (plotted_time(end)-plotted_time(1)) > 2*3600 )
                temp_tick_loc = temp_tick_loc + (2*60*60);
            else
                temp_tick_loc = temp_tick_loc + (60*60);
            end
            % Append to existing vectors
            tick_loc = [tick_loc, temp_tick_loc];
            tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
                'mmm-dd HH:MM')]; % Label includes month and day
        end
    end
else % x-tick location is not every hour
    % Find when days begin
    offset = mod(start_time, 24*60*60);
    tick_loc = start_time - offset;
    % If x ticks are weekly or monthly spaced, change the start date
    if (x_tick_location == 2) % Begin tick_loc on first day of week
        while weekday(datestr(unixtime(tick_loc))) ~= 1 %~= %+(24*60*60)
            tick_loc = tick_loc + (24*60*60); 
        end
    elseif (x_tick_location == 3) % Begin tick_loc on first day of month
        while day(datestr(unixtime(tick_loc))) ~= 1
            tick_loc = tick_loc + (24*60*60);
        end
    end
    if(x_tick_location == 3) % Label in format of months
        tick_label = datestr(unixtime(tick_loc), 'mm-yyyy');
    else % Label in format of days of month
        tick_label = datestr(unixtime(tick_loc), 'dd-mmm-yyyy');
    end
    temp_tick_loc = tick_loc;
    % Create vector of tick_loc and tick_label
    if (tot_time <= 86400) % tot_time is less than a day
        while temp_tick_loc(end) < time(end)
            temp_tick_loc = temp_tick_loc + (24*60*60);
            if (x_tick_location == 2) % Week format
                if weekday(datestr(unixtime(temp_tick_loc))) == 1
                    tick_loc = [tick_loc temp_tick_loc];
                    tick_label = [tick_label; ...
                        datestr(unixtime(tick_loc(end)),'dd-mmm-yyyy')];
                end
            elseif (x_tick_location == 3) % Month format
                if day(datestr(unixtime(temp_tick_loc))) == 1
                    tick_loc = [tick_loc temp_tick_loc];
                    tick_label = [tick_label; ...
                        datestr(unixtime(tick_loc(end)),'mm-yyyy')];
                end
            else % Day format
                tick_loc = [tick_loc; (tick_loc(end)+(24*60*60))];
                tick_label = [tick_label; ...
                    datestr(unixtime(tick_loc(end)),'dd-mmm-yyyy')];
            end
        end
    else % tot_time is greater than a day
        offset = mod(plotted_time(1), 24*60*60);
        tick_loc = plotted_time(1) - offset;
        while temp_tick_loc(end) < plotted_time(end)
            temp_tick_loc = temp_tick_loc + (24*60*60);
            if (x_tick_location == 2)
                if weekday(datestr(unixtime(temp_tick_loc))) == 1
                    tick_loc = [tick_loc temp_tick_loc];
                    tick_label = [tick_label; ...
                        datestr(unixtime(tick_loc(end)),'dd-mmm-yyyy')];
                end
            elseif (x_tick_location == 3)
                if day(datestr(unixtime(temp_tick_loc))) == 1
                    tick_loc = [tick_loc temp_tick_loc];
                    tick_label = [tick_label; ...
                        datestr(unixtime(tick_loc(end)),'mm-yyyy')];
                end
            else % Day format
                tick_loc = [tick_loc; (tick_loc(end)+(24*60*60))];
                tick_label = [tick_label; ...
                    datestr(unixtime(tick_loc(end)),'dd-mmm-yyyy')];
            end
        end
    end
end

if isempty(plotted_time)
    plotted_time = time;
    plotted_agc = agc;
end

%% Set Plot Parameters
% Set x axis limits
if (tot_time <= 86400)
    xlim([min(time), max(time)]);
else
    xlim([min(plotted_time)-2, max(plotted_time)+2]);
end
ylim([0.1 1.35])
set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
ylabel('AGC Value [V]');
xlabel('UTC Time');
end
