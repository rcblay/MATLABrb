addpaths;

datafileAGC = '/home/dma/sige_code/data/TESTasdfghjk';
i = 1; %channel

fidA = fopen(datafileAGC);
fseek(fidA,0,1);

n = 3; % How often to update in seconds, SHOULD BE AT LEAST 3 sec (for now)
m = 30; % How much previous data to visualize in seconds
% Pauses for n seconds, starts with new data created once function starts,
% meaning no previous data is shown
pause(n);

datestring = out((12+lenLog):end-4);
filename = conv_to_unixtime(datestring);
start_time = filename; % Day collection began

file = dir(datafileAGC);
size = file.bytes;
sizeMod = mod(size,14);
size14 = size - sizeMod; % Size as rounded down to multiple of 22
N = size14 / 14; % N represents number of rows of 22 bytes
% Read in times, and register value
times = fread(fidA, N, 'uint64', 6);
fseek(fidA, 8, -1);
regs = fread(fidA, [6 N], '6*uint8', 8);
regs = regs';
fclose(fidA);

times = times/1000 + start_time -times(1)/1000;

temp = bitand(regs(:,1),48);
Chn = bitshift(temp,-4);
Ch = Chn + 1;

temp6 = bitand(regs(:,6),31);
ApproxGain = 2.779*temp6 + 1.9864;
% Check which channel first byte is (Might be unnecessary if always
% Channel 1)
offset = Ch(1) - 1;
if offset ~= 0
    offset = 4 - offset;
end

j = i + offset;

AGC = ApproxGain(j:4:end);

plot(times,AGC,'-*b')

[tick_loc,tick_label] = scale_x_axis(start_time,times(end));
pause(1);
% Set Plot Parameters
% Set x axis limits
xlim([min(Data.(varNamePlottedTime))-2, max(Data.(varNamePlottedTime))+2]);
set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label
xlabel('UTC Time');
hold off