function [filetime] = conv_to_unixtime(datestring)
% conv_to_unixtime changes datestring format into ten digit unixtime stamp
% datestring is YYYY-mm-ddTHH-MM-SS
year = str2num(datestring(1:4));
month = str2num(datestring(6:7));
day = str2num(datestring(9:10));
hour = str2num(datestring(12:13));
minute = str2num(datestring(15:16));
second = str2num(datestring(18:19));
% Creates date_vec that unixtime can convert
date_array = [year month day hour minute second];
filetime = unixtime(date_array);
end