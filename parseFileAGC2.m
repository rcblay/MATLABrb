function [time_k2, ApproxGain3,RF_GainSt3] = parseFileAGC2(filename,Channels,timerange,TimeStart,Day)
% parseFileAGC2: Function that parses regdump.bin file from NT1065 and  
%                plots meaningful data like RF Gain.
% Inputs: filename: directory + filename of file to parse
%         Channels: Channels to plot, e.g. 1, [1 2], [1 3 4]
%         timerange: Timerange in hrs to plot from start, e.g. [0.2 22.2]
%         TimeStart: Time data collection started, e.g 16.6 = 16:36
%         Day: What day past the start of data collection, e.g. 0,1,2,3
%
% Outputs: Plots of meaningful data from registers of NT1065

%% Open File and Read in Data
tic;
fid2 = fopen(filename,'r');
file = dir(filename);
size = file.bytes;
sizeMod = mod(size,22);
size22 = size - sizeMod; % Size as rounded down to multiple of 22
N = size22 / 22; % N represents number of rows of 22 bytes
% Read in absolute sample number, times, and register value
absSN = fread(fid2,N,'uint64',14);
fseek(fid2,8,-1);
times = fread(fid2, N, 'uint64', 14) ;
fseek(fid2, 16, -1);
regs = fread(fid2, [6 N], '6*uint8', 16) ;
regs = regs';

%% Parse Register Values
% Channel
temp = bitand(regs(:,1),48);
Chn = bitshift(temp,-4);
Ch = Chn + 1;
% TScode90
temp2 = bitand(regs(:,3),3);
temp3 = bitshift(temp2,8);
TS_code90 = temp3 + regs(:,4);
% RFAGC_DownUp
temp4 = bitand(regs(:,5),48);
RF_AGC_DownUp = bitshift(temp4,-4);
% RF_GainSt
temp5 = bitand(regs(:,5),15);
RF_GainSt = 0.9667.*temp5 + 11;
% Gain
temp6 = bitand(regs(:,6),31);
ApproxGain = 2.779*temp6 + 1.9864;

%% Split Values into Four Channels
modulus = mod(N,4);
for i = 1:4
    if i > modulus
        time_k(:,i) = [times(i:4:end); 0];
        Temp(:,i) = 417.2 - 0.722*[TS_code90(i:4:end); 0];
        RF_AGC_DownUp2(:,i) = [RF_AGC_DownUp(i:4:end); 0];
        RF_GainSt2(:,i) = [RF_GainSt(i:4:end); 0];
        ApproxGain2(:,i) = [ApproxGain(i:4:end); 0];
    else
        time_k(:,i) = times(i:4:end);
        Temp(:,i) = 417.2 - 0.722*TS_code90(i:4:end);
        RF_AGC_DownUp2(:,i) = RF_AGC_DownUp(i:4:end);
        RF_GainSt2(:,i) = RF_GainSt(i:4:end);
        ApproxGain2(:,i) = ApproxGain(i:4:end);
    end
end

toc

%% Save only Data in TimeRange Given
len = length(Channels);
time_k = time_k/3600000;
for i = 1:4
    if i > modulus
        ind = find(time_k(:,i) > timerange(1));
        ind2 = find(time_k(:,i) < timerange(2));
        try
            time_k2(:,i) = time_k(ind(1):ind2(end-2),i);
            Temp2(:,i) = Temp(ind(1):ind2(end-2),i);
            RF_AGC_DownUp3(:,i) = RF_AGC_DownUp2(ind(1):ind2(end-2),i);
            RF_GainSt3(:,i) = RF_GainSt2(ind(1):ind2(end-2),i);
            ApproxGain3(:,i) = ApproxGain2(ind(1):ind2(end-2),i);
        catch
            try
                time_k2(:,i) = time_k(ind(1):ind2(end-3),i);
                Temp2(:,i) = Temp(ind(1):ind2(end-3),i);
                RF_AGC_DownUp3(:,i) = RF_AGC_DownUp2(ind(1):ind2(end-3),i);
                RF_GainSt3(:,i) = RF_GainSt2(ind(1):ind2(end-3),i);
                ApproxGain3(:,i) = ApproxGain2(ind(1):ind2(end-3),i);
            catch
                time_k2(:,i) = time_k(ind(1):ind2(end-1),i);
                Temp2(:,i) = Temp(ind(1):ind2(end-1),i);
                RF_AGC_DownUp3(:,i) = RF_AGC_DownUp2(ind(1):ind2(end-1),i);
                RF_GainSt3(:,i) = RF_GainSt2(ind(1):ind2(end-1),i);
                ApproxGain3(:,i) = ApproxGain2(ind(1):ind2(end-1),i);
                
            end
        end
    else
        ind = find(time_k(:,i) > timerange(1));
        ind2 = find(time_k(:,i) < timerange(2));
        try
            time_k2(:,i) = time_k(ind(1):ind2(end-1),i);
            Temp2(:,i) = Temp(ind(1):ind2(end-1),i);
            RF_AGC_DownUp3(:,i) = RF_AGC_DownUp2(ind(1):ind2(end-1),i);
            RF_GainSt3(:,i) = RF_GainSt2(ind(1):ind2(end-1),i);
            ApproxGain3(:,i) = ApproxGain2(ind(1):ind2(end-1),i);
        catch
            try
                time_k2(:,i) = time_k(ind(1):ind2(end-2),i);
                Temp2(:,i) = Temp(ind(1):ind2(end-2),i);
                RF_AGC_DownUp3(:,i) = RF_AGC_DownUp2(ind(1):ind2(end-2),i);
                RF_GainSt3(:,i) = RF_GainSt2(ind(1):ind2(end-2),i);
                ApproxGain3(:,i) = ApproxGain2(ind(1):ind2(end-2),i);
            catch
                time_k2(:,i) = time_k(ind(1):ind2(end),i);
                Temp2(:,i) = Temp(ind(1):ind2(end),i);
                RF_AGC_DownUp3(:,i) = RF_AGC_DownUp2(ind(1):ind2(end),i);
                RF_GainSt3(:,i) = RF_GainSt2(ind(1):ind2(end),i);
                ApproxGain3(:,i) = ApproxGain2(ind(1):ind2(end),i);
                
            end
            
        end
    end
    
end

% NOTE: HERE SHOULD BE CHECK FOR EVENTS
% ApproxGain3 has to be sorted and split into event and not event as well
% as its corresponding time, and then plotted together
% If below 26 dB, then check if next sample is below as well

% WILL NOT WORK FOR MULTIPLE CHANNELS HAVING EVENTS BECAUSE
% EVENTTIME/EVENTGAIN WILL BE DIFF LENGTHS FOR EACH CHANNEL. FIX

for i = 1:len
    k = 1;
    for ii = 1:length(ApproxGain3(:,Channels(i)))-1
        if ApproxGain3(ii,Channels(i)) < 26
            if ApproxGain3(ii+1,Channels(i)) < 26
                EventTime(k,Channels(i)) = time_k2(ii,Channels(i));
                EventGain(k,Channels(i)) = ApproxGain3(ii,Channels(i));
                k = k + 1;
            end
        end
    end
end

%% Plots Data
% Transforms time to UTC time
time_k2 = time_k2 + TimeStart - Day*24;
if exist('EventTime','var')
    EventTime = EventTime + TimeStart - Day*24;
end

for i = 1:len
    figure;
    subplot(4,1,1)
    plot(time_k2(:,Channels(i)),Temp2(:,Channels(i)),'*g')
    ylabel({'Temp' '[Celsius]'})
    title(['Channel ' num2str(Channels(i))])
    axis tight
    subplot(4,1,2)
    plot(time_k2(:,Channels(i)),RF_AGC_DownUp3(:,Channels(i)),'*c')
    ylabel({'0: In Range' '1: Low' '2: High' '3: Imposs'})
    %title(['RF AGC Indicator of Input Signal Power Ch' num2str(Channels(i))])
    axis tight
    subplot(4,1,3)
    plot(time_k2(:,Channels(i)),RF_GainSt3(:,Channels(i)),'*r')
    ylabel({'RF' 'Gain [dB]'})
    %title(['RF Gain Value Ch' num2str(Channels(i))])
    axis tight
    subplot(4,1,4)
    hold on
    plot(time_k2(:,Channels(i)),ApproxGain3(:,Channels(i)),'-*b')
    if exist('EventTime','var')
        plot(EventTime,EventGain,'*r')
    end
    ylabel({'IF' 'Gain [dB]'})
    %title(['IFA Gain Value at T= +25 C Ch' num2str(Channels(i))])
    xlabel('Time of Day (24 Hr Clock)')
    axis tight
    samexaxis('join','yld',0.75);
    %set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 30 20])
    %saveas(gcf,['Plots/Ch' num2str(Channels(i)) '.png'])
    %saveas(gcf,['Plots/Ch' num2str(Channels(i)) '.fig'])
end

end
