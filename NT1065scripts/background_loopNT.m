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
            if strcmp(out(1:lenLog),logname) == 0
                continue;
            end
            % Filename set to %Y-%m-%dT%H-%M-%S then converted to unixtime
            datestring = out((12+lenLog):end-4);
            filename = conv_to_unixtime(datestring);
            start_time = filename; % Day collection began
            plotdate = unixtime(filename); % Changes to date vector
            strdate = datestr(plotdate,0);
            strdate(strdate == ' ') = '_';
            strdate(strdate == ':') = '-'; % Required
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
            clear Data
        else
            continue; % If not AGC file, then go to next file
        end
    end
    
    %% Spectrum Plots, TODO
    
    for j = 3:nf
        % Check if file is a triggered or nominal
        extendedlogname = [logname, '_AGC'];
        [a,b] = regexp(D(j).name,[extendedlogname,'(_nominal_|_ch1_triggered_',...
            '|_ch2_triggered_|_ch3_triggered_|_ch4_triggered_)(.)*.bin$'],...
            'start','tokens'); 
        if(~isempty(a))
            date = conv_to_unixtime(b{1}{2});
            % Obtains file name
            c = regexp(D(j).name,'(.)*.bin$','tokens');
            % Print filename on terminal
            fprintf(['[',logname,']',c{1}{1},'...']);
            plotdate = unixtime(date);
            strdate = datestr(plotdate,0);
            strdate2 = strdate;
            strdate(strdate == ' ') = '_';
            strdate(strdate == ':') = '-';
            if strcmp(b{1}{1},'_nominal_') % Checks for nominal, else trigger
                % Names file for automatically saved data (23 hours)
                namefile = [logname,'_SpectroNominal_',strdate];
                unpck_filename = 'tempnom.bin';
            else
                % Names file for triggered auto save (below threshold)
                chan = b{1}{1}(4);
                namefile = [logname,'_SpectroTrigger',num2str(chan),'_',strdate];
                unpck_filename = ['temptrig_ch' num2str(chan) '_output.bin'];
                trigtime = strdate;
            end
            % FIX TODO
            % Check if exists already, and if so skips to next file
            if(exist([out_folder,'/',namefile,'.jpg'],'file'))
                fprintf('EXISTS\n');
                continue;
            end
            % Check for corresponding IF file
            is_IF = 0;
            for k = 3:nf % Another for loop of same files
                % Search for match
                if k ~= j
                    date1 = char(c{1});
                    date1 = date1(end-18:end);
                    date2 = D(k).name(end-22:end-4);
                    if strcmp(date1,date2)
                        is_IF = 1;
                        break;
                    end
                end
            end
            %unpack_NT1065_4chn([folder '/' D(k).name],unpck_filename);
            % NEED AGC for all four channels parsed !!:
            Data4ch = parseAGC4channel([folder '/' D(j).name],date);
            % Loop through 4 channels and do tracking, spectro, and
            % plotting
            % Ch1-L1, Ch2-GloL1, Ch3-GloL2, Ch4-L2
            for chann = 1:4
                figNum = 300 + chann;
                % Spectro part
                % Activate_IF_generation set inside init.m
                if((is_IF==1) && (activate_IF_generation==1))
                    % Need init settings for sampling freq, msToProcess,
                    % fileName
                    if chann == 1 % GPS L1
                        stt = Data4ch.Time4ch_Ch1;
                        sagc = Data4ch.AGC4ch_Ch1;
                        initSettingsL1; % Necessary
                        sampling_freq = settings.samplingFreq;
                        settings.msToProcess = floor((stt(end)-(stt(1)+0.1))*1000);
                        unpackfilename = [unpck_filename(1:end) '.c0']; %change back
                        settings.fileName = unpackfilename;
                        init_trackingL1;
                        unpacked_coeff = 2;
                        centerfreq = 1575.42e6;
                        interfreq = 14.58e6;
                        namefile_ch = [namefile '_ch1'];
                        channelNr = 1;
                        plotSpectrumPlotNT(figNum,stt,sagc,trackResults,channelNr,...
                            unpackfilename,sampling_freq,unpacked_coeff,...
                            centerfreq,interfreq,offset,out_folder,namefile_ch,logname)
                    end
                    if chann == 2 % Glonass L1
                        stt = Data4ch.Time4ch_Ch2;
                        sagc = Data4ch.AGC4ch_Ch2;
                        initSettingsGL; % Necessary
                        sampling_freq = settings.samplingFreq;
                        settings.msToProcess = floor((stt(end)-(stt(1)+0.1))*1000);
                        unpackfilename = [unpck_filename(1:end-4) '2.bin'];
                        settings.fileName = unpackfilename;
                        settings.L1L2 = 1; % 1 for L1, 0 for L2
                        settings.inputCenter     = 1602e6; 
                        init_trackingGL;
                        unpacked_coeff = 4;
                        centerfreq = 1602e6;
                        interfreq = 60e3;
                        namefile_ch = [namefile '_ch2'];
                        plotSpectrumPlotNT(figNum,stt,sagc,trackResults,channelNr,...
                            unpackfilename,sampling_freq,unpacked_coeff,...
                            centerfreq,interfreq,offset,out_folder,namefile_ch,logname)
                    end
                    if chann == 3 % Glonass L2
                        stt = Data4ch.Time4ch_Ch3;
                        sagc = Data4ch.AGC4ch_Ch3;
                        initSettingsGL; % Necessary
                        sampling_freq = settings.samplingFreq; % 6.625e6
                        settings.msToProcess = floor((stt(end)-(stt(1)+0.1))*1000);
                        unpackfilename = [unpck_filename(1:end-4) '3.bin'];
                        settings.fileName = unpackfilename;
                        settings.L1L2 = 0; % 1 for L1, 0 for L2
                        settings.inputCenter     = 1246e6; 
                        init_trackingGL;
                        unpacked_coeff = 4;
                        centerfreq = 1246e6;
                        interfreq = 60e3;
                        namefile_ch = [namefile '_ch3'];
                        plotSpectrumPlotNT(figNum,stt,sagc,trackResults,channelNr,...
                            unpackfilename,sampling_freq,unpacked_coeff,...
                            centerfreq,interfreq,offset,out_folder,namefile_ch,logname)
                    end
                    if chann == 4 % GPS L2
                        stt = Data4ch.Time4ch_Ch4;
                        sagc = Data4ch.AGC4ch_Ch4;
                        initSettingsL2; % Necessary
                        sampling_freq = settings.samplingFreq;
                        settings.msToProcess = floor((stt(end)-(stt(1)+0.1))*1000);
                        unpackfilename = [unpck_filename(1:end-4) '4.bin'];
                        settings.fileName = unpackfilename;
                        init_trackingL2;
                        unpacked_coeff = 4;
                        centerfreq = 1227.6e6;
                        interfreq = 60e3;
                        namefile_ch = [namefile '_ch4'];
                        plotSpectrumPlotNT(figNum,stt,sagc,trackResults,channelNr,...
                            unpackfilename,sampling_freq,unpacked_coeff,...
                            centerfreq,interfreq,offset,out_folder,namefile_ch,logname)
                    end
                end
                  
            end
            % Need to alter find_file with trig for four channels
%             if strcmp(unpck_filename(1:8),'temptrig') && emailtrig == 1
%                 dailyplot = find_file_with_trig(trigtime,folder,lenLog);
%                 attachments = {[out_folder,'/',namefile,'.jpg'],...
%                     dailyplot};
%                 time = namefile(21:end);
%                 send_trig_email(time,logname,attachments,recipients);
%             end
        end
        
    end

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
%     if weekday(datestr(clock,'mm/dd/yy')) - Ahead_Behind == 1 && weekendemail == 1
%         weekend_email(logname,recipients,out_folder,folder,thresh,pts_under_thrsh);
%     end
    
    % Check if files are still growing
    if is_data_logging == 1
        if isGrow ~= 1 && nf > 4
            error_email(logname,recipients,folder);
        end
    end
    
    pause(pausetime);
end
