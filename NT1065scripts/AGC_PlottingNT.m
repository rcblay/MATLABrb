function [Data] = AGC_PlottingNT(start_time,end_time,directory,file_name,...
    thresh,pts_under_thrsh,channels)
% input:
%   start_time:       start time for plotting (unix timestamp)
%   end_time:         end time for plotting (unix timestamp)
%   directory:        directory where the AGC data files are located
%   file_name:        search name for AGC data files (ex.
%                       /*korea_AGC*.bin')
%   thresh:           threshold of AGC data that defines when the reciever
%                       detects jammers or spoofers
%   pts_under_thrsh   amount of points under threshold to constitute a
%                       trigger
%   channels:         channels to plot
% output:
%   plot of the AGC data between the start and end times
%   Data:             All information in vectors with named variables.

%% Check Inputs are Same Size
if ~((length(thresh) == length(channels)) && (length(pts_under_thrsh) == ...
        length(channels)))
    error('Inputs have different lengths, i.e. not same amount of channels');
end

%% Find Files in Time Range
rawData = dir(strcat(directory,file_name));% Lists files that match format
% Get the unix times from the file names
fileNames = {rawData.name}; % Cell arrays with names
% Match date
fileDate_str = regexp(fileNames, 'AGC_daily_(.)*.bin$', 'tokens'); 
fileDate_str = [fileDate_str{:}]; % Concatenate all cells into one string
if(isempty(fileNames)) % No files found, return
    disp(['No AGC files were found in the directory '...
        'that matched the file name']);
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
    return;
end
fileDate = fileDate(file_index); % Now only dates in time range

%% Initialize Plotted Vectors
for i = 1:length(channels)
    varNamePlottedTime = ['Plotted_Time_Ch' num2str(channels(i))];
    varNamePlottedTemp = ['Plotted_Temp_Ch' num2str(channels(i))];
    varNamePlottedStatus = ['Plotted_Status_Ch' num2str(channels(i))];
    varNamePlottedRFGain = ['Plotted_RFGain_Ch' num2str(channels(i))];
    varNamePlottedIFGain = ['Plotted_IFGain_Ch' num2str(channels(i))];
    varNamePlottedEventAGC = ['Plotted_Event_AGC_Ch' num2str(channels(i))];
    varNamePlottedEventTime = ['Plotted_Event_Time_Ch' num2str(channels(i))];
    Data.(varNamePlottedTime) = [];
    Data.(varNamePlottedTemp) = [];
    Data.(varNamePlottedStatus) = [];
    Data.(varNamePlottedRFGain) = [];
    Data.(varNamePlottedIFGain) = [];
    Data.(varNamePlottedEventAGC) = [];
    Data.(varNamePlottedEventTime) = [];
end

%% Plot files in Time Range
% Iterate through the files that are potentially in the time range and
% plot them
for ii = 1:length(fileNames)
    % Open files and read them in
    fid = fopen(char(strcat(directory, '/', fileNames(ii))));
    file = dir(char(strcat(directory, '/', fileNames(ii))));
    size = file.bytes;
    sizeMod = mod(size,14);
    size14 = size - sizeMod; % Size as rounded down to multiple of 22
    N = size14 / 14; % N represents number of rows of 22 bytes
    % Read in times, and register value
    times = fread(fid, N, 'uint64', 6);
    fseek(fid, 8, -1);
    regs = fread(fid, [6 N], '6*uint8', 8);
    regs = regs';
    fclose(fid);
    
    times = times/1000 + start_time -times(1)/1000;
    
    % Parse Register Values
    % Channel
    temp = bitand(regs(:,1),48);
    Chn = bitshift(temp,-4);
    Ch = Chn + 1;
    % TScode90
    temp2 = bitand(regs(:,3),3);
    temp3 = bitshift(temp2,8);
    TS_code90 = temp3 + regs(:,4);
    % RFAGC_DownUp
    temp4 = bitand(regs(:,5),48);
    RF_AGC_DownUp = bitshift(temp4,-4);
    % RF_GainSt
    temp5 = bitand(regs(:,5),15);
    RF_GainSt = 0.9667.*temp5 + 11;
    % Gain
    temp6 = bitand(regs(:,6),31);
    ApproxGain = 2.779*temp6 + 1.9864;
    % Check which channel first byte is (Might be unnecessary if always
    % Channel 1)
    offset = Ch(1) - 1;
    if offset ~= 0
        offset = 4 - offset;
    end
    
    %% Assign Data to Struct
    len = length(channels);
    for i = 1:len
        % Assign Data
        j = i + offset;
        varNameTime = ['Time_Ch' num2str(channels(i))];
        varNameTemp = ['Temp_Ch' num2str(channels(i))];
        varNameStatus = ['RF_Status_Ch' num2str(channels(i))];
        varNameRFGain = ['RF_Gain_Ch' num2str(channels(i))];
        varNameIFGain = ['IF_Gain_Ch' num2str(channels(i))];
        Data.(varNameTime) = times(j:4:end);
        Data.(varNameTemp) = 417.2 - 0.722*TS_code90(j:4:end);
        Data.(varNameStatus) = RF_AGC_DownUp(j:4:end);
        Data.(varNameRFGain) = RF_GainSt(j:4:end);
        Data.(varNameIFGain) = ApproxGain(j:4:end);
        % ASSUMES TIME IN FILE IS UNIX TIME (Can easily fix by adding
        % filename as start time...hopefully)
        % Find times that are in the time range
        time_index = find(Data.(varNameTime) >= start_time & Data.(varNameTime)...
            <= end_time);
        % Sets time to only the time in time range
        Data.(varNameTime) = Data.(varNameTime)(time_index);
        if (~isempty(time_index)) % If not empty (expected), but could be empty
            Data.(varNameTemp) = Data.(varNameTemp)(time_index);
            Data.(varNameStatus) = Data.(varNameStatus)(time_index);
            Data.(varNameRFGain) = Data.(varNameRFGain)(time_index);
            Data.(varNameIFGain) = Data.(varNameIFGain)(time_index);
            % Start counter for triggers
            k = 1;
            % Checks for trigger events
            varNameEventAGC = ['Event_AGC_Ch' num2str(channels(i))];
            varNameEventTime = ['Event_Time_Ch' num2str(channels(i))];
            for m = 1:length(Data.(varNameIFGain))-pts_under_thrsh(i)
                if Data.(varNameIFGain)(m:m+pts_under_thrsh(i)-1) < thresh(i)
                    Data.(varNameEventAGC)(k,1) = Data.(varNameIFGain)(m);
                    Data.(varNameEventTime)(k,1) = Data.(varNameTime)(m);
                    k = k + 1;
                end
            end
            
            % Update Plotted Vectors
            varNamePlottedTime = ['Plotted_Time_Ch' num2str(channels(i))];
            varNamePlottedTemp = ['Plotted_Temp_Ch' num2str(channels(i))];
            varNamePlottedStatus = ['Plotted_Status_Ch' num2str(channels(i))];
            varNamePlottedRFGain = ['Plotted_RFGain_Ch' num2str(channels(i))];
            varNamePlottedIFGain = ['Plotted_IFGain_Ch' num2str(channels(i))];
            varNamePlottedEventAGC = ['Plotted_Event_AGC_Ch' num2str(channels(i))];
            varNamePlottedEventTime = ['Plotted_Event_Time_Ch' num2str(channels(i))];
            Data.(varNamePlottedTime) = [Data.(varNamePlottedTime); ...
                Data.(varNameTime)];
            Data.(varNamePlottedTemp) = [Data.(varNamePlottedTemp); ...
                Data.(varNameTemp)];
            Data.(varNamePlottedStatus) = [Data.(varNamePlottedStatus); ...
                Data.(varNameStatus)];
            Data.(varNamePlottedRFGain) = [Data.(varNamePlottedRFGain); ...
                Data.(varNameRFGain)];
            Data.(varNamePlottedIFGain) = [Data.(varNamePlottedIFGain); ...
                Data.(varNameIFGain)];
            if k > 1
                Data.(varNamePlottedEventAGC) = [Data.(varNamePlottedEventAGC); ...
                    Data.(varNameEventAGC)];
                Data.(varNamePlottedEventTime) = [Data.(varNamePlottedEventTime); ...
                    Data.(varNameEventTime)];
            end
            % Check if there was no data plotted and return
            if isempty(Data.(varNamePlottedTime))
                disp('No data was found for the time range specified');
                return;
            end
        end
    end
end

%% Plot all Channels
for i = 1:len
    varNamePlotID = ['Plot_ID_Ch' num2str(channels(i))];
    Data.(varNamePlotID) = figure;
    hold on
    varNamePlottedTime = ['Plotted_Time_Ch' num2str(channels(i))];
    varNamePlottedTemp = ['Plotted_Temp_Ch' num2str(channels(i))];
    varNamePlottedStatus = ['Plotted_Status_Ch' num2str(channels(i))];
    varNamePlottedRFGain = ['Plotted_RFGain_Ch' num2str(channels(i))];
    varNamePlottedIFGain = ['Plotted_IFGain_Ch' num2str(channels(i))];
    varNamePlottedEventAGC = ['Plotted_Event_AGC_Ch' num2str(channels(i))];
    varNamePlottedEventTime = ['Plotted_Event_Time_Ch' num2str(channels(i))];
    subplot(4,1,1)
    plot(Data.(varNamePlottedTime),Data.(varNamePlottedTemp),'*g')
    set(gca,'FontSize',16) % not sure how it affects figure
    ylabel({'Temp' '[Celsius]'})
    title(['NT1065 Channel ', num2str(channels(i)), ' AGC Data (from ', ...
        datestr(unixtime(start_time)), ' to ', ...
        datestr(unixtime(end_time)), ' [UTC])']);
    set(gca,'FontSize',15) % not sure how it affects figure
    axis tight
    subplot(4,1,2)
    plot(Data.(varNamePlottedTime),Data.(varNamePlottedStatus),'*c')
    ylabel({'0: In Range' '1: Low' '2: High' '3: Imposs'})
    set(gca,'FontSize',15) % not sure how it affects figure
    axis tight
    subplot(4,1,3)
    plot(Data.(varNamePlottedTime),Data.(varNamePlottedRFGain),'*r')
    ylabel({'RF' 'Gain [dB]'})
    set(gca,'FontSize',15) % not sure how it affects figure
    axis tight
    subplot(4,1,4)
    hold on
    plot(Data.(varNamePlottedTime),Data.(varNamePlottedIFGain),'-*b')
    set(gca,'FontSize',15) % not sure how it affects figure
    % Plot Triggers
    if length(Data.(varNamePlottedEventAGC)) > 1
        plot(Data.(varNamePlottedEventTime),Data.(varNamePlottedEventAGC),'*r')
    end
    ylabel({'IF' 'Gain [dB]'})
    set(gca,'FontSize',16) % not sure how it affects figure
    axis tight
    samexaxis('join','yld',0.75);
    
    %% Scale the X-Axis
    % Check if the x ticks are supposed to be every hour
    [tick_loc,tick_label] = scale_x_axis(start_time,end_time);
    pause(1);
    %% Set Plot Parameters
    % Set x axis limits
    xlim([min(Data.(varNamePlottedTime))-2, max(Data.(varNamePlottedTime))+2]);
    set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
    set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
    xlabel('UTC Time');
    hold off
end

%% Plot IF Gain for All Channels, TODO

end
