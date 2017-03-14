function [filetime] = conv_to_unixtime(datestring)
% conv_to_unixtime changes datestring format into ten digit unixtime stamp
% datestring is YYYY-mm-ddTHH-MM-SS

datestring(11) = ' ';
datestring([14 17]) = ':';
date_array = datevec(datestring);
filetime = unixtime(date_array);
end