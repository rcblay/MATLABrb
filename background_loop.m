% Background Loop
% Description: Infinite while loop that checks every day whether there is
% a new file to read in and plot. Plots Daily AGC, Daily Spectrum plots,
% and any Trigger Spectrum Plots.

while (1) 
    %% Plot the Daily AGC data
    D = dir(folder); % D is struct of contents of folder, i.e. SiGe data
    nf = numel(D); % Number of files/directories in folder is set to nf
    % Loops through files, and checks whether any need to be plotted
    for i = (3:nf) % Skips to 3 because 1 and 2 are . and ..
        file=D(i).name; 
        out = char(file); % Changes from cell to string
        % Change start from 4 to 5 depending on log, i.e. not CU
        stuff = out(4:end-28); %19 for unixtime stamp
        fileAGC = char('AGC');
        % If CU_AGC file, (excludes AUTO or TRIGGER files or other files)
        if strcmp(stuff,fileAGC) == 1 
            % Filename set to %Y-%m-%dT%H-%M-%S then converted to unixtime
            datestring = out(8:end-8);
            filename = conv_to_unixtime(datestring);
            start_time = filename; % Day collection began
            end_time = start_time + (24*60*60); % Day collection ended
            x_tick_location = 0; % 0 refers to hourly plot
            plotdate = unixtime(filename);
            strdate = datestr(plotdate);
            strdate(strdate == ' ') = '_';
            strdate(strdate == ':') = '-';
            FN = [logname,'_DailyAGC_',strdate];
            % Checks to see if figure already exists, if so, then not 
            % plotted, prints to terminal that figure has already been 
            % plotted
            if(exist([out_folder,'/',FN,'.fig'],'file')) 
                fprintf(['[',logname,']',out, '...']);
                fprintf(' EXISTS\n');
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
            % If jpg does not already exists, then it enters AGC_plotting
            % to be plotted. x_tick_location = 0 for hourly x ticks
            [fid, ~, ~] = AGC_Plotting(start_time, end_time,folder, ...
                ['/*' logname '_AGC*AGC.bin'], x_tick_location,thresh,...
                pts_under_thrsh);
            if (fid ~= -1) % If file exists, title it, set size, and save
                title(gca, [logname ' Daily AGC Data (from ', ...
                    datestr(unixtime(start_time)), ' to ', ...
                    datestr(unixtime(end_time)), ' [UTC])']);grid;
                set(fid,'units','normalized','outerposition',[0 0 1 1])
                set(gca,'FontSize',16)
                saveas(fid, [out_folder '/' logname '_DailyAGC_', ...
                    strdate, '.fig']); 
                saveas(fid, [out_folder '/' logname '_DailyAGC_', ...
                    strdate, '.jpg']);
                close(fid);
            end
        else
            continue; % If not CU_AGC file, then go to next file
        end
    end
    
    %% Generate Spectro Plots if Files are Available
    % Look for the captured part, if below threshold, this plot is plotted
    % or every 23 hours.
    % Loops through every file and check if any need Spectro Plots
    for j = 3:nf % 1 and 2 are . and ..
        % Checks for any DETECT or AUTO plots, a is start index and b is
        % cell of matches
        initSettings; % Necessary
        [a,b] = regexp(D(j).name,[logname,...
            '(_DETECT_|_AUTO_)(.)*.AGC.bin$'],'start','tokens'); 
        if(~isempty(a)) % Not empty, meaning it is a DETECT/AUTO file
            date = conv_to_unixtime(b{1}{2});
            sampling_freq = 16.3676e6/4; % Oscillator freq divided by 4
            trig_value = 0;
            % Checks for D(j).name match, c is CU_AGC_%Y-%m-%dT%H-%M-%S
            c = regexp(D(j).name,'(.)*.AGC.bin$','tokens'); 
            % Get AGC and Time values of this file
            % binary conversion when opening, b refers to big endian
            fid = fopen([folder,'/',D(j).name],'rb');
            data = fread(fid,'uint32'); % read bin data in 4 byte chunks
            fclose(fid); % Close file
            % De-entrelace data
            stt = data(2:2:end); % time
            stt = interpTime(stt);
            % ADC has 3.3V range & 12 bits give 4096 (2^12) discrete steps
            sagc = data(1:2:end)*3.3/4096; 
            % Find start_time and end_time of this file
            if (stt(1)>=start_time)||(stt(end)<=end_time) % Is unnecessary?
                fprintf(['[',logname,']',c{1}{1},'...']);
                % Save the captured info for the sum up on
                % continuous AGC saving plot
                plotdate = unixtime(date);
                strdate = datestr(plotdate);
                strdate2 = strdate;
                strdate(strdate == ' ') = '_';
                strdate(strdate == ':') = '-';
                if strcmp(b{1}{1},'_AUTO_') % Checks for AUTO, else DETECT
                    % Names file for automatically saved data (23 hours)
                    namefile = [logname,'_SpectroNominal_',strdate]; 
                    unpck_filename = 'tempnom.bin';
                else
                    % Names file for triggered auto save (below threshold)
                    namefile = [logname,'_SpectroTriggered_',strdate];
                    unpck_filename = 'temptrig.bin';
                    trigtime = strdate;
                end
                % Check if exists already, and if so skips to next file
                if(exist([out_folder,'/',namefile,'.jpg'],'file'))
                    fprintf('EXISTS\n');
                    continue;
                end
                % Look for the associated IF file to see if it exists
                is_IF = 0;
                for k = 3:nf % Another for loop of same files
                    % Search for match
                    d = regexp(D(k).name,[c{1}{1},'.IF.bin$'],'start'); 
                    if(~isempty(d))
                        is_IF = 1;
                        break;
                    end
                end
                % Plot the spectrogram and the AGC
                h_fig = figure(919); % Assigns figure handle
                set(h_fig,'Renderer','painters'); % Sorts graphic objects
                set(h_fig,'Units','pixels'); % Sets units to be pixels
                % Defines border distances and dimensions
                set(h_fig,'units','normalized','outerposition',[0 0 1 1]) 
                % Spectro axis sets location inside a 1x1 square and font
                h_spectr = axes('Position',[0.1 0.1 0.4 0.70],...
                    'FontSize',8); 
                % AGC axes sets location inside a 1x1 square
                h_agc_CNo = axes('Position', [0.55 0.1 0.30 0.70]); 
                % Spectro part
                % Activate_IF_generation set inside init.m
                if((is_IF==1) && (activate_IF_generation==1)) 
                    % Tracking results
                    % Settings set in initSettings.m, skips 2 seconds
                    settings.msToProcess = floor((stt(end)-(stt(1)+0.1))*1000); 
                    start_time = stt(1);
                    unpack_cplx([folder,'/',c{1}{1},'.IF.bin'], ...
                        unpck_filename); % Unpack & change name to temp.bin
                    settings.fileName = unpck_filename;
                    init_tracking;
                    if(isempty(trackResults))
                        plot(sagc,stt-stt(1),'k'); % plot AGC black
                        h_agc_CNo = gca;
                        set(h_agc_CNo, 'yticklabel', []);
                        set(h_agc_CNo,'FontSize',16)
                        xlabel('AGC value [V]'); % Label x-axis
                        xlim(h_agc_CNo, [0.0 1.4]); % Even spaces on x-axis
                    else 
                        % Plot the tracking results
                        timeAxisInSeconds = (1:settings.msToProcess)/1000;
                        channelNr = 1;
                        % Create graphs with x-axis on both top and bottom
                        [h_agc_CNo, ~, ~] = plotxx(sagc,stt-stt(1)...
                            ,trackResults(channelNr).CNo.VSMValue,...
                            trackResults(channelNr).CNo.VSMIndex/1000,...
                            {'AGC value [V]', 'C/No (dB-Hz)'}, {'',''}); 
                        % Above: AGC, VSM value, VSM index/1000, Label: AGC
                        % value, Label: Hz, nothing on y axes
                        % Set axis properties
                        set(h_agc_CNo(1),'Position',[0.55 0.1 0.30 0.70]...
                            ,'yticklabel',[])
                        set(h_agc_CNo(2),'Position',[0.55 0.1 0.30 0.70]...
                            ,'yticklabel', [], 'YColor', 'r')
                        set(h_agc_CNo(1),'FontSize',16)
                        set(h_agc_CNo(2),'FontSize',16)
                        xlim(h_agc_CNo(1), [0.0 1.4]);
                        xlim(h_agc_CNo(2), [25 55]);
                    end
                    % Spectro
                    
                    % Below should be spectrum producer without unpacking
                    % again
                    % Unpacked is 4*size of packed, goes from 2 bits to one
                    % byte for SiGe Data
                    unpacked_coeff = 4; 
                    [F,T,P] = spectro(unpck_filename,1024,sagc,steps_atten,...
                        steps_agc,sampling_freq,unpacked_coeff);  
                    h_spectr_plot = pcolor(h_spectr,F*1e-6,T,10*log10(P));
                    set(h_spectr_plot,'LineStyle','none'); % No line
                end
                % Do a bunch of fancy settings to make plot look nice
                ylabel(h_spectr,'Time [s]','FontSize',16); % Time
                xlabel(h_spectr,'Frequency [MHz]','FontSize',16); % Freq
                % Title
                UTC_time = datenum([1970 1 1 0 0 stt(1)]);
                title_fig = {logname,['First Unix Timestamp : ',...
                    num2str(stt(1))],['First UTC Time : ',...
                    datestr(UTC_time)]}; % 2 times
                title ('Parent',h_spectr,title_fig,'Units','normalized',...
                    'Position',[1.0 1.2],'VerticalAlignment','middle',...
                    'FontSize',12);
                % Colorbar
                h_colorbar = colorbar('peer',h_spectr,'NorthOutside');
                set(h_colorbar,'Position',[0.1 0.8 0.4 0.01]);
                set(h_colorbar,'FontSize',16)
                colormap(jet(1024));
                colormark = 10*log10(P);
                maxcolor = max(max(colormark));
                mincolor = min(min(colormark));
                set(h_spectr,'CLim',[mincolor maxcolor]); % Color spectrum
                set(h_spectr,'FontSize',16)
                % Clear tracking results
                clearvars -except nf start_time end_time h_fig ...
                    out_folder namefile D period trig_value var ...
                    processed last_modified_date steps_agc steps_atten ...
                    folder activate_IF_generation calib_file ...
                    sampling_freq logname MyExternalIP weekendemail ...
                    MyExternalIP z i thresh pts_under_thrsh emailtrig ...
                    recipients unpck_filename trigtime grow_check localUTC
                saveas(h_fig,[out_folder,'/',namefile,'.jpg']);
                close(h_fig);
                fprintf('SAVED\n');
                if strcmp(unpck_filename,'temptrig.bin') && emailtrig == 1
                    dailyplot = find_file_with_trig(trigtime,folder);
                    attachments = {[out_folder,'/',namefile,'.jpg'],...
                        dailyplot};
                    time = namefile(21:end);
                    send_trig_email(time,logname,attachments,recipients);
                end
            end
        end
    end
    c = regexp(D(i).name,'(.)*.bin$','tokens');

    cl = clock;
    % Finds amount of seconds until 5 pm to pause
    if cl(4) < localUTC % If less than 5 pm
        pausetime = (localUTC-cl(4)-1)*3600 + (60-cl(5))*60 + floor(60-cl(6));
    else % If greater than 5 pm
        pausetime = (24-cl(4)+localUTC-1)*3600 + (60-cl(5))*60 + floor(60-cl(6));
    end
    % Long sleep to make it very low frequency
    disp(['Work done! Next loop in ',num2str(pausetime),' sec. at 00:00 UTC']);
    close all;
    % Sunday, won't work 100 % if it is started on Sunday
    if weekday(datestr(clock,'mm/dd/yy')) == 1 && weekendemail == 1
        weekend_email(logname,recipients,out_folder);
    end
    pause(pausetime);
end
