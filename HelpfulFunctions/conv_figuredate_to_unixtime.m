function [filetime] = conv_figuredate_to_unixtime(datestring)
% conv_figuredate_to_unixtime changes datestring format into ten digit unixtime stamp
% datestring is dd-mmm-yyyy_HH-MM-SS

datestring(datestring == '_') = ' ';
datestring([15 18]) = ':';
date_array = datevec(datestring);
filetime = unixtime(date_array);
end