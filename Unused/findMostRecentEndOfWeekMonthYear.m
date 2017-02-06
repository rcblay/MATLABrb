function [eow_unix, eom_unix, eoy_unix ] = findMostRecentEndOfWeekMonthYear( input_time )
%findMostRecentEndOfWeekMonthYear : takes in the input time as unix time
%   and finds the unix time of the most recent end of the week(eow_unix), 
%   the most recent end of the month (eom_unix), and the most recent end 
%   of the year (eoy_unix).
%input:
%   input_time:       time in unix time
%output:
%   eow_unix: the unix time of the most recent Sunday before the input time
%   eom_unix: the unix time of the most recent 1st day of the month before
%           the input time
%   eoy_unix: the unix time of the most recent 1st day of the year before
%           the input time
input_time_formatted = unixtime(input_time); %get input date and time
input_yr = input_time_formatted(1);
input_month = input_time_formatted(2);
input_day = input_time_formatted(3);

day_of_week = weekday(datestr(unixtime(input_time))); %finds whichda of the week it is
eow_unix = unixtime([input_yr, input_month, input_day-(day_of_week-1), 0, 0, 0]);

eom_unix = unixtime([input_yr, input_month, 1, 0, 0, 0]);

eoy_unix = unixtime([input_yr, 1, 1, 0, 0, 0]);

end

