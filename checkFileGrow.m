function isGrow = checkFileGrow(filename)
% checkFileGrow just ascertains whether the file in question is still
% growing by checking the byte size of the file
fileold = dir(filename);
oldbytes = fileold.bytes;
pause(12); % 10 seconds is minimum time that file updates
filenew = dir(filename);
newbytes = filenew.bytes;
if oldbytes == newbytes % File is not growing
    isGrow = 0; 
elseif newbytes > oldbytes % File is growing
    isGrow = 1;
else
    isGrow = -1; % Error
end

end