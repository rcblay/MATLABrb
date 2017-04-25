function attachments = gather_week_plots(out_folder,folder,start_time,...
    end_time,logname,thresh,pts_under_thrsh)
% This function gets all the files for the past week and returns them in
% attachments.

[fid, ~, ~] = AGC_Plotting(start_time, end_time,folder, ...
    ['/*' logname '_AGC*AGC.bin'],thresh,pts_under_thrsh);
if (fid ~= -1) % If file exists, title it, set size, and save
    title(gca, [logname ' Weekly AGC Data (from ', ...
        datestr(unixtime(start_time)), ' to ', ...
        datestr(unixtime(end_time)), ' [UTC])']);grid;
    set(fid,'units','normalized','outerposition',[0 0 1 1])
    set(gca,'FontSize',16)
    date = unixtime(start_time); % Change to date vector
    strdate = datestr(date);
    strdate(strdate == ' ') = '_';
    strdate(strdate == ':') = '-';
    weekplotname = [out_folder '/' logname '_WeekAGC_', strdate, '.jpg'];
    saveas(fid, weekplotname);
    attachments{1} = weekplotname;
    close(fid);
end

% Next search for trigger spectrum plots
% Change all dates in trigger spectrum plots to unixtime and compare to
% starttime and endtime

D = dir(out_folder);
nf = numel(D); % Number of files/directories in folder is set to nf
k = 2;
for j = 3:nf
    % Find date strings from spectro files
    [a,b] = regexp(D(j).name,[logname,...
        '(_SpectroNominal_|_SpectroTriggered_)(.)*.jpg$'],'start',...
        'tokens');
    if ~isempty(a)
        date_unixtime = conv_figuredate_to_unixtime(b{1}{2});
        if date_unixtime >= start_time && date_unixtime <= end_time
            attachments{k} = [out_folder '/' D(j).name];
            k = k + 1;
        end
    end
end 

end