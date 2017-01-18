%Automated script to plot AGC weekly data
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

function Weekly_Automated_AGC(D, logname, threshold, out_folder, current_time)

AGC_file_name = ['/*' logname '_AGC*AGC.bin']; %station_name = logname
%Define number of points per day for the week plot
points = 50000;
x_tick_location = 1; %daily spacing
%%%%%%%%%%%%%

%find the starting file
[end_time, ~, ~] = findMostRecentEndOfWeekMonthYear(current_time);
start_time = end_time - (7*24*60*60);

        
[fid, ~, ~] = AGC_Plotting(start_time, end_time, points, D, AGC_file_name, threshold, x_tick_location);
if (fid ~= -1)
    title(gca, [logname ' Weekly AGC Data (from ', datestr(unixtime(start_time)), ' to ', datestr(unixtime(end_time)), ' [UTC])']);
    saveas(fid, [out_folder '/' logname '_WeeklyAGC_', num2str(floor(start_time)), '.jpg']);
    close(fid);
end