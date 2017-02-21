% This script changes all files with unixtime (i.e. ten digit timestamps)
% to files with the date string. Does need to be in same folder as function
% unixtime.

% BE CAREFUL: If logname is different than CU or SU then it will need to be
% changed slightly. Also, there are very specific cases that will not
% produce good results, but those should never be seen.

folder = '/home/dma/Documents/CUvsSUcompare/data/SU_SiGe'; % Location of files

D = dir(folder); % D is struct of contents of folder
nf = numel(D); % Number of files/directories in folder is set to nf
for i = (3:nf) % Skips to 3 because 1 and 2 are . and ..
    filename = D(i).name; 
    out = char(filename); % Changes from cell to string
    
    if length(out) < 20
        continue;
    end
    % For all cases of filenames, finds timestamp and before/after segments
    if out(4:6) == 'AGC'
        timestamp = str2num(out(8:17));
        if out(18) == 'T'
            continue;
        end
        before = out(1:7);
        after = out(18:end);
    elseif out(4:7) == 'AUTO'
        timestamp = str2num(out(9:18));
        if out(19) == 'T'
            continue;
        end
        before = out(1:8);
        after = out(19:end);
    elseif out(4:9) == 'DETECT'
        timestamp = str2num(out(11:20));
        if out(21) == 'T'
            continue;
        end
        before = out(1:10);
        after = out(21:end);
    end
    if isempty(timestamp) % Means not 10 digit time stamp
        continue;
    end
    datevec = unixtime(timestamp);
    % Adds preceding zero if less than 10
    for i = 1:6
        if datevec(i) < 10
            datestring{i} = ['0' num2str(datevec(i))];
        else
            datestring{i} = num2str(datevec(i));
        end
    end
    datestr = [datestring{1} '-' datestring{2} '-' datestring{3} 'T' ...
        datestring{4} '-' datestring{5} '-' datestring{6}];
    
    newfile = [before datestr after];
    movefile([folder '/' filename],[folder '/' newfile],'f');
end



