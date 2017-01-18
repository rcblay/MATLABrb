%Automated script to plot AGC monthly data
%
%==========================================================================
%Inputs:  
%       1) D = the directory to scan for AGC files
%       2) AGC_file_name = the file name of the desired AGC data files
%       3) threshold = the defined AGC threshold value that will trigger a detection for a station
%       4) x_tick_location = determines the spacing of the x-axis tick marks. 0 = hourly spacing, 1 = daily spacing, 2 = weekly spacing, 3 = monthly spacing.
%==========================================================================
%Outputs:
%   1) Plots full data for the most recent week (Sunday to Sunday)
%
%      Output time is UTC
%==========================================================================
% Dependant Functions: unixtime, findMostRecentEndOfWeekMonthYear,
%           AGC_Plotting, 
%==========================================================================
%%

function Monthly_Automated_AGC(D, station_name, threshold, out_folder, current_time)

AGC_file_name = ['/*' station_name '_AGC*AGC.bin'];
%Define number of points per day for the week plot
points = 50000;
x_tick_location = 2; %weekly spacing
%%%%%%%%%%%%%

%find the starting file
[~, end_time, ~] = findMostRecentEndOfWeekMonthYear(current_time);
end_time_full = unixtime(end_time-(24*60*60));
days_in_the_month = eomday(end_time_full(1), end_time_full(2));
start_time = end_time - (days_in_the_month*24*60*60);

[fid, ~, ~] = AGC_Plotting(start_time, end_time, points, D, AGC_file_name, threshold, x_tick_location);
if (fid ~= -1)
    title(gca, [station_name ' AGC Data for ', datestr(end_time_full, 'mmmm yyyy')]);
    saveas(fid, [out_folder '/' station_name '_MonthlyAGC_', num2str(floor(start_time)), '.jpg']);
    close(fid);
end

end
