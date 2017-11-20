clear
close all
clc

folder = '/mnt/admin/Brandon_Idaho/Night1/NT1065';
out_folder = [folder,'/figures'];
if ~exist(out_folder,'dir')
    mkdir(out_folder); % Make new folder called out_folder
end

lenLog = 5;
thresh = [0 0 0 0];
pts_under_thrsh = [5 5 5 5];
channels = 1:4;

D = dir(folder);
nf = numel(D); % Number of files/directories in folder is set to nf
for i = 3:nf
    if D(i).isdir == 0
        file = D(i).name;
        out = char(file);
        logname = out(1:lenLog);
        datestring = out(lenLog+12:end-4);
        filename = conv_to_unixtime(datestring);
        plotdate = unixtime(filename);
        strdate = datestr(plotdate,0);
        strdate(strdate == ' ') = '_';
        strdate(strdate == ':') = '-'; % Required
        start_time = filename; % Day collection began
        
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
        
        fid = fopen(char(strcat(folder, '/', file)));
        fileD = dir(char(strcat(folder, '/', file)));
        size = fileD.bytes;
        sizeMod = mod(size,14);
        size14 = size - sizeMod; % Size as rounded down to multiple of 22
        N = size14 / 14; % N represents number of rows of 22 bytes
        % Read in times, and register value
        times = fread(fid, N, 'uint64', 6);
        fseek(fid, 8, -1);
        regs = fread(fid, [6 N], '6*uint8', 8);
        regs = regs';
        fclose(fid);
        end_time = floor(start_time + times(end)/1e3 -times(1)/1e3); % time since start----
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
        
        for ii = 1:4
            LongvarNamePlotID = ['Data.Plot_ID_Ch' num2str(channels(ii))];
            varNamePlotID = ['Plot_ID_Ch' num2str(channels(ii))];
            plot_ID = Data.(varNamePlotID);
            if exist('plot_ID','var')
                set(plot_ID,'units','normalized','outerposition',[0 0 1 1]);
                saveas(plot_ID, [out_folder '/' logname '_DailyNT_Ch', ...
                    num2str(channels(ii)),'_',strdate, '.fig']);
                saveas(plot_ID, [out_folder '/' logname '_DailyNT_Ch', ...
                    num2str(channels(ii)),'_',strdate, '.jpg']);
                close(plot_ID);
            end
        end
        clear Data
    end
end

