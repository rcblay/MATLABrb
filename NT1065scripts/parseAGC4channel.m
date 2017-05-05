function [Data] = parseAGC4channel(filename,start_time)
% Read in agc file and get time and IF agc (can add RF agc if needed)
% Open files and read them in
fid = fopen(filename);
file = dir(filename);
size = file.bytes;
sizeMod = mod(size,14);
size14 = size - sizeMod; % Size as rounded down to multiple of 22
N = size14 / 14; % N represents number of rows of 22 bytes
% Read in times, and register value
times = fread(fid, N, 'uint64', 6);
fseek(fid, 8, -1);
regs = fread(fid, [6 N], '6*uint8', 8);
regs = regs';
fclose(fid);

times = times/1000 + start_time -times(1)/1000;

% Parse Register Values
% Channel
temp = bitand(regs(:,1),48);
Chn = bitshift(temp,-4);
Ch = Chn + 1;
% % TScode90
% temp2 = bitand(regs(:,3),3);
% temp3 = bitshift(temp2,8);
% TS_code90 = temp3 + regs(:,4);
% % RFAGC_DownUp
% temp4 = bitand(regs(:,5),48);
% RF_AGC_DownUp = bitshift(temp4,-4);
% % RF_GainSt
% temp5 = bitand(regs(:,5),15);
% RF_GainSt = 0.9667.*temp5 + 11;
% Gain
temp6 = bitand(regs(:,6),31);
ApproxGain = 2.779*temp6 + 1.9864;
% Check which channel first byte is (Might be unnecessary if always
% Channel 1)
offset = Ch(1) - 1;
if offset ~= 0
    offset = 4 - offset;
end
%% Assign Data to Struct
for i = 1:4
    % Assign Data
    j = i + offset;
    varNameTime = ['Time4ch_Ch' num2str(i)];
    varNameIFGain = ['AGC4ch_Ch' num2str(i)];
    Data.(varNameTime) = times(j:4:end);
    Data.(varNameIFGain) = ApproxGain(j:4:end);
end
end