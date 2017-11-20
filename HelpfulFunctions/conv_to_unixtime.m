function [filetime] = conv_to_unixtime(datestring)
% conv_to_unixtime changes datestring format into ten digit unixtime stamp
% datestring is YYYY-mm-ddTHH-MM-SS

datestring(11) = ' '; % gets rid of T
datestring([14 17]) = ':'; % converts dashes in time to :
date_array = datevec(datestring); % converts to vector of date
filetime = unixtime(date_array); % converts to seconds from unix epoch

end