function [filetime] = conv_to_unixtime(datestring)

% datestring is %Y-%m-%dT%H-%M-%S

year = str2num(datestring(1:4));
month = str2num(datestring(6:7));
day = str2num(datestring(9:10));
hour = str2num(datestring(12:13));
minute = str2num(datestring(15:16));
second = str2num(datestring(18:19));

date_array = [year month day hour minute second];
filetime = unixtime(date_array);

end