function [ week_plot, month_plot, year_plot ] = checkAutoPlotGeneration( current_time , out_folder)
%checkAutoPlotGeneration
%   Takes in the current time in unix time and the directory where the
%   figures are stored.
%
%   The function returns a boolean for if an automatic plot should be
%   generated for weekly data, monthly data, and yearly data. True means a
%   plot should be created and false means a plot should not be created

%find the most recent unix time of the end of the week, month, and year
[eow_unix, eom_unix, eoy_unix] = findMostRecentEndOfWeekMonthYear(current_time);

%load the names of the automatically generated figures
weekly_plotDate = [];
monthly_plotDate = [];
yearly_plotDate = [];

weekly_plot_files = dir(strcat(out_folder, '/*WeeklyAGC_*.jpg'));
weekly_plotNames = [weekly_plot_files.name];
if (~isempty(weekly_plotNames))
    weekly_plotDate = regexp(weekly_plotNames, '\d{10,10}', 'match'); %matched with names
end

monthly_plot_files = dir(strcat(out_folder, '/*MonthlyAGC_*.jpg'));
monthly_plotNames = [monthly_plot_files.name];
if (~isempty(monthly_plotNames))
    monthly_plotDate = regexp(monthly_plotNames, '\d{10,10}', 'match');
end

yearly_plot_files = dir(strcat(out_folder, '/*YearlyAGC_*.jpg'));
yearly_plotNames = [yearly_plot_files.name];
if (~isempty(yearly_plotNames))
    yearly_plotDate = regexp(yearly_plotNames, '\d{10,10}', 'match');
end

week_plot = false;
month_plot = false;
year_plot = false;

if ((current_time-eow_unix) > (24*60*60)) && (isempty(weekly_plotDate) || isempty(find(ismember(weekly_plotDate, num2str(eow_unix - (7*24*60*60) )))))
    week_plot = true; %create plot if it's a new week
end

eom = unixtime(eom_unix-(24*60*60));
days_in_the_month = eomday(eom(1), eom(2));
eom_unix = eom_unix - (days_in_the_month*24*60*60);
if ((current_time-eom_unix) > (24*60*60)) && (isempty(monthly_plotDate) || isempty(find(ismember(monthly_plotDate, num2str(eom_unix)))))
    month_plot = true; %create plot if it's a new month
end

eoy = unixtime(eoy_unix-(24*60*60));
days_in_the_year = yeardays(eoy(1));
eoy_unix = eoy_unix - (days_in_the_year*24*60*60);
if ((current_time-eoy_unix) > (24*60*60)) && (isempty(yearly_plotDate) || isempty(find(ismember(yearly_plotDate, num2str(eoy_unix)))))
    year_plot = true; %create plot if it's a new year
end


end

