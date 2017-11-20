function [tick_loc,tick_label] = scale_x_axis(start_time,end_time)

% Depending on time between start and end, the ticks will be at different
% locations with different labels. Should be nice label values.

tot_time = end_time - start_time;
tick_loc = [];
tick_label = [];

%% Find the correct scale
% Intervals- 0: 15 sec, 1: 1 min, 2: 2 min, 3: 5 min, 4: 15 min, 5: 30 min
% 6: 1 hr, 7: 2 hr, 8: 6 hr, 9: 1 day, 10: 2 day, 11: 1 Week, 12: 1 Month

if tot_time <= 30 % interval every 5 sec
    offset = mod(start_time, 5); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
    % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM:SS');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 5;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM:SS')];
    end
elseif tot_time <= 1.5*60 % interval every 15 sec
    offset = mod(start_time, 15); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
    % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM:SS');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 15;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM:SS')];
    end
elseif tot_time <= 3*60 % interval every 15 sec
    offset = mod(start_time, 30); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM:SS');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 30;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM:SS')];
    end
elseif tot_time <= 12*60 % interval every min
    offset = mod(start_time, 60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 20*60 % interval every 2 min
    offset = mod(start_time, 2*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 2*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 50*60 % interval every 5 min
    offset = mod(start_time, 5*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 5*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 2.5*60*60 % interval every 15 min
    offset = mod(start_time, 15*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 15*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 5*60*60 % interval every 30 min
    offset = mod(start_time, 30*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 30*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 10*60*60 % interval every hr
    offset = mod(start_time, 60*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 60*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 86400 % interval every 2 hrs
    offset = mod(start_time, 2*60*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 2*60*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 2*86400 % interval every 4 hours
    offset = mod(start_time, 4*60*60); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'HH:MM');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 4*60*60;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'HH:MM')];
    end
elseif tot_time <= 12*86400 % interval every day
    offset = mod(start_time, 86400); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'dd-mmm-yyyy');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 86400;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'dd-mmm-yyyy')];
    end
elseif tot_time <= 24*86400 % interval every 2 days
    offset = mod(start_time, 2*86400); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'dd-mmm-yyyy');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 2*86400;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'dd-mmm-yyyy')];
    end
elseif tot_time <= 12*7*86400 % interval every week
    offset = mod(start_time, 7*86400); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'dd-mmm-yyyy');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 7*86400;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'dd-mmm-yyyy')];
    end
else % interval every month
    offset = mod(start_time, 7*86400); % Find hours after day start
    tick_loc = start_time-offset; % Find start of day by subtracting offset
     % Create tick_label for first hour
    tick_label = datestr(unixtime(tick_loc), 'mm-yyyy');
    temp_tick_loc = tick_loc;
    while tick_loc(end) < end_time
        temp_tick_loc = temp_tick_loc + 7*86400;
        tick_loc = [tick_loc, temp_tick_loc];
        tick_label = [tick_label; datestr(unixtime(tick_loc(end)),...
            'mm-yyyy')];
    end
end
    