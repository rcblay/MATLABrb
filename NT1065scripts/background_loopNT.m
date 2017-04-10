% Background Loop
% Description: Infinite while loop that checks every day whether there is
% a new file to read in and plot. Plots Daily AGC, Daily Spectrum plots,
% and any Trigger Spectrum Plots.

%% Checks if Inputs are Same Size
if ~((length(thresh) == length(channels)) && (length(pts_under_thrsh) == ...
        length(channels)))
    error('Inputs have different lengths, i.e. not same amount of channels');
end

while (1) 
    if Ahead_Behind == 0 % Behind
        offset = [', (Local: UTC-',num2str(24-localUTC),')'];
    else % Ahead
        offset = [', (Local: UTC+',num2str(localUTC),')'];
    end
    %% Plot the Daily AGC data
    D = dir(folder); % D is struct of contents of folder, i.e. SiGe data
    nf = numel(D); % Number of files/directories in folder is set to nf
    % Loops through files, and checks whether any need to be plotted
    lenLog = length(logname);
    for i = 3:nf % Skips to 3 because 1 and 2 are . and ..
        file=D(i).name; 
        out = char(file); % Changes from cell to string
        % Change start from 4 to 5 depending on log, i.e. not CU
        stuff = out((2+lenLog):end-30); % CU_AGC_Daily_Date.bin
        fileAGC = char('AGC');
        % If CU_AGC file, (excludes AUTO or TRIGGER files or other files)
        if strcmp(stuff,fileAGC) == 1 
            % Filename set to %Y-%m-%dT%H-%M-%S then converted to unixtime
            datestring = out((12+lenLog):end-4);
            filename = conv_to_unixtime(datestring);
            start_time = filename; % Day collection began
            plotdate = unixtime(filename); % Changes to date vector
            strdate = datestr(plotdate,0);
            strdate(strdate == ' ') = '_';
            strdate(strdate == ':') = '-';
            len = length(channels);
            for ii = 1:len
                FN{ii} = [logname,'_DailyNT_Ch',num2str(channels(ii)),...
                    '_',strdate];
            end
            % Checks to see if figure already exists, if so, then not 
            % plotted, prints to terminal that figure has already been 
            % plotted
            for ii = 1:len
                if(exist([out_folder,'/',FN{ii},'.fig'],'file'))
                    fprintf(['[',logname,']',out, ' Ch', num2str(ii),'...']);
                    fprintf(' EXISTS\n');
                    k(ii) = 1;
                else
                    k(ii) = 0;
                    break
                end
            end
            % Means all channels exist
            if ii == len && k(ii) == 1
                continue;
            end
            % Check if file is still growing
            if grow_check == 1
                isGrow = checkFileGrow([folder '/' out]);
                % If still growing, skip file
                if isGrow == 1
                    continue;
                end
            end
            
            % Find end_time by looking at last time entry in file
            fid = fopen(char([folder, '/', file]));
            file = dir(char([folder, '/', file]));
            size = file.bytes;
            sizeMod = mod(size,14);
            size14 = size - sizeMod; % Size as rounded down to multiple of 14
            N = size14 / 14; % N represents number of rows of 14 bytes
            % Read in times, and register value
            times = fread(fid, N, 'uint64', 6);
            fclose(fid);
            end_time = start_time + times(end)/1e3 -times(1)/1000; % time since start----
            % If jpg does not already exists, then it enters AGC_plottingNT
            % to be plotted.
            [Data] = AGC_PlottingNT(start_time, end_time,folder, ...
                ['/*' logname '_AGC*.bin'],thresh,pts_under_thrsh,...
                channels);
            for ii = 1:len
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
        else
            continue; % If not AGC file, then go to next file
        end
    end
    
    %% Spectrum Plots, TODO

    %% Find Time to UTC and send Emails
    cl = clock;
    % Finds amount of seconds until UTC to pause
    if cl(4) < localUTC % If less than UTC
        pausetime = (localUTC-cl(4)-1)*3600 + (60-cl(5))*60 + floor(60-cl(6));
    else % If greater than UTC
        pausetime = (24-cl(4)+localUTC-1)*3600 + (60-cl(5))*60 + floor(60-cl(6));
    end
    % Long sleep to make it very low frequency
    disp(['Work done! Next loop in ',num2str(pausetime),' sec. at 00:00 UTC']);
    close all;
    % Sunday, won't work 100 % if it is started on Sunday
    if weekday(datestr(clock,'mm/dd/yy')) - Ahead_Behind == 1 && weekendemail == 1
        weekend_email(logname,recipients,out_folder,folder,thresh,pts_under_thrsh);
    end
    
    % Check if files are still growing
    if is_data_logging == 1
        if isGrow ~= 1 && nf > 4
            error_email(logname,recipients,folder);
        end
    end
    
    pause(pausetime);
end
