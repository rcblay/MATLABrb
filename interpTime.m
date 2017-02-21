function timeInterpolated = interpTime(time)
% interpTime takes a time vector that has values bunched in intervals and
% spaces them out equally between the intervals

% Time is interpolated from one second to another
j = 1; % current index of time
k = length(time); % length of time so it knows when to stop
% Loops through every sec interval
for ij = 1:(time(end)-time(1)) % should be 86400-1
    temp = time(j); % set first value to temp
    l = 1; % l is counter of spot from one sec to another
    if (j+1) == k || j == k % Breaks if at end of time
        break;
    end
    % While still the starting sec, go to next value
    while temp == time(j+l)
        l = l + 1;
        if (j+l) == k % Breaks if at end of time
            break;
        end
    end
    if (j+l) == k % Breaks if at end of time
        break;
    end
    diff = time(j+l) - temp; % Finds difference, should be one second
    interval = diff/l; % Finds space between each value
    for m = 1:l % Loop through and interpolate for every value
        time(j+m-1) = time(j+m-1) + (m-1)*interval;
    end
    j = j + l; % Update j to next second
end

timeInterpolated = time;
end