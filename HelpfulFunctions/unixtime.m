function [outputtime] = unixtime(inputtime) 
% unixtime either transforms ten digit timestamp code to a date vector or
% transforms a date vector to a ten digit unix timestamp

% unixtime is seconds since 1.1.1970
% matlabtime is days after 1.1.0000

if size(inputtime,1) == 0 %no input time
   outputtime = [];
else
    if size(inputtime,2) == 6 % 6 columns of input time, datevec
        unixstart = zeros(size(inputtime,1),6); % makes everything in the first row 0
        for count = 1:size(inputtime,1)
            unixstart(count,:) = [1970,1,1,0,0,0];
        end
        outputtime = etime(inputtime,unixstart); %converts to unixtime
    elseif size(inputtime,2) == 1 % 1 column of input time, timestamp
        secs = floor(inputtime); % round down to the next integer
        nanosecs = inputtime - secs;
        unixstart = [1970,1,1,0,0,0];
        matlabtime = datenum(unixstart) + secs/86400; %turns date to serial date number 
        outputtime = datevec(matlabtime); %convert date and time to vector of components
        outputtime(:,6) = outputtime(:,6) + nanosecs; %converts to matlab time
    else
        error('wrong format of input matrix');
    end
end