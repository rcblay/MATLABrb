function calcTime = calcDateTime(weekNumber,TOW)
% Calculate time in year,month,day,hour,minute,second
% from the GPS time (week, TOW)
% Not UTC time
%
% calcTime = calcDateTime(weekNumber,TOW)
%
%   Inputs:
%       weekNumber      - GPS week number
%       TOW             - GPS time of week
%   Outputs:
%       calcTime        - time structure (year,month,day,hour,minute,second)

JAN61980 = 44244; %Modified Julian Date (MJD) for the initial epoch of GPS Time
JAN11901 = 15385; %MJD for 0 hours, Jan 1, 1901
SECPERDAY = 86400; %Number of seconds in a day
MONPERDAY = 0.032; %Approx. number of months in a day

%Initialize an array to represent the day of the year
%at the beginning of each month

regularYear = [0 31 59 90 120 151 181 212 243 273 304 334 365 ];
leapYear    = [0 31 60 91 121 152 182 213 244 274 305 335 366 ];

%Find Modified Julian Date and Fraction of Day
mjd     = weekNumber*7 + floor(TOW/SECPERDAY) + JAN61980;
fmjd    = mod(TOW,SECPERDAY)/SECPERDAY;

%Find Year, Day of Year, Hours, Minutes and Seconds

daysFromJan11901    = mjd - JAN11901;
num4years           = floor(daysFromJan11901/1461); %1461 = 365+365+365+366
yearsSoFar          = 1901 + 4*num4years;
daysLeft            = daysFromJan11901 - 1461*num4years;
lastFewYears        = floor(daysLeft/365) - floor(daysLeft/1460);% The second term accounts for a leap year
year                = floor(yearsSoFar + lastFewYears);
dayofYear           = floor(daysLeft - 365*lastFewYears+1);
hour                = floor(fmjd * 24);
minute              = floor(fmjd*1440 - hour*60);
second              = fmjd*SECPERDAY - hour*3600 - minute*60;

guess=floor(dayofYear*MONPERDAY + 1);
more=0;

if (mod(year,4)== 0)
    if ((dayofYear - leapYear(guess+1)) > 0)
        more = 1;
    end
        month = guess + more;
        dayofMonth = dayofYear - leapYear(month);
    
else
    
    if ((dayofYear - regularYear(guess+1)) > 0)
        more = 1;
    end
        month = guess + more;
        dayofMonth = dayofYear - regularYear(month);
    
end

calcTime.year                = year;
calcTime.dayofYear           = dayofYear;
calcTime.month               = month;
calcTime.day                 = dayofMonth;
calcTime.hour                = hour;
calcTime.minute              = minute;
calcTime.second              = second;

