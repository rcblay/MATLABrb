function filename = find_file_with_trig(trigtime,folder,lenLog)
% This function finds the filename that would theoretically have the
% trigtime that is inputted. For example, if the file is a day long, and
% the trig time happened at 02:00 UTC on Wednesday, this will find the
% filename that has that time.

% Need to get array of all filenames that are daily agc files and see if
% the trigtime is included in their range

% First make trigtime right format for conv_to_unixtime, then all that is
% needed is changing filename to be the file in figures with the different
% format

trigtime2 = [trigtime(1:11) ' ' trigtime(13:14) ':' trigtime(16:17) ...
    ':' trigtime(19:20)];
trigtime3 = datestr(datenum(trigtime2),30);
trigtime4 = [trigtime3(1:4) '-' trigtime3(5:6) '-' trigtime3(7:11) ...
    '-' trigtime3(12:13) '-' trigtime3(14:15)];

trig_timestamp = conv_to_unixtime(trigtime4);

D = dir(folder); % D is struct of contents of folder, i.e. SiGe data
nf = numel(D); % Number of files/directories in folder is set to nf
% Loops through files, and checks whether any need to be plotted
for i = (3:nf) % Skips to 3 because 1 and 2 are . and ..
    file=D(i).name;
    out = char(file); % Changes from cell to string
    stuff = out((lenLog+2):end-28); %19 for unixtime stamp
    logname = out(1:lenLog);
    fileAGC = char('AGC');
    % If CU_AGC file, (excludes AUTO or TRIGGER files or other files)
    if strcmp(stuff,fileAGC) == 1
        % Filename set to %Y-%m-%dT%H-%M-%S then converted to unixtime
        datestring = out(8:end-8);
        filename2 = conv_to_unixtime(datestring);
        start_time = filename2; % Day collection began
        fid = fopen(char([folder, '/', file]));
        data = fread(fid, 'uint32'); % read bin file 4 bytes at a time
        fclose(fid);
        time = data(2:2:end);
        end_time = time(end); % Day collection ended
        if trig_timestamp >= start_time && trig_timestamp <= end_time
            plotdate = unixtime(filename2);
            strdate = datestr(plotdate);
            strdate(strdate == ' ') = '_';
            strdate(strdate == ':') = '-';
            filename = [folder,'/figures','/',logname,'_DailyAGC_',...
                strdate,'.jpg'];
            break;
        end
    end
end

end