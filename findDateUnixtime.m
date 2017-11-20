% ad hoc script

lenLog = 3;

out = char(file); % Changes from cell to string
datestring = out((10+lenLog):end-7);
datestring(11) = ' ';
datestring([14 17]) = ':';
date_array = datevec(datestring);
filetime = unixtime(date_array);
plotdate = unixtime(filename); % Changes to date vector