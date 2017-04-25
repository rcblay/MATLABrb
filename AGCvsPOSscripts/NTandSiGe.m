% Plot NT1065 Channel 1 with SiGe

fid = fopen('smoothedAGC.bin','r');
AGC_SiGe = fread(fid,'double');
fid = fopen('TimeSiGe.bin','r');
Time_SiGe = fread(fid,'double');
fid = fopen('agcNTch1.bin');
agcCh1 = fread(fid,'double');
fid = fopen('unixtimeNTch1.bin');
timeCh1 = fread(fid,'double');

ind = find(Time_SiGe <= timeCh1(end));
Time_SiGe = Time_SiGe(ind);
AGC_SiGe = AGC_SiGe(ind);

pts_under_thrsh = 5;
thresh = 0.7;
k = 1;
for i = 1:length(AGC_SiGe)-pts_under_thrsh
    if AGC_SiGe(i:i+pts_under_thrsh-1) < thresh
        EventAGC(k) = AGC_SiGe(i);
        EventTime(k) = Time_SiGe(i);
        k = k + 1;
    end
end

pts_under_thrsh = 2;
thresh = 42;
k = 1;
for i = 1:length(agcCh1)-pts_under_thrsh
    if agcCh1(i:i+pts_under_thrsh-1) < thresh
        EventNTAGC(k) = agcCh1(i);
        EventNTTime(k) = timeCh1(i);
        k = k + 1;
    end
end


start_time = timeCh1(1);
end_time = timeCh1(end);

figure;
hold on
subplot(2,1,1)
hold on
plot(Time_SiGe,AGC_SiGe,'go','MarkerSize',4,'MarkerFaceColor','g');
plot(EventTime,EventAGC,'ro','MarkerSize',4,'MarkerFaceColor','r');
ylim([0.1 0.9])
xlim([start_time end_time])
ylabel('AGC Value [V] (SiGe)','FontSize',16)
title('Drive Test: SiGe vs NT1065','FontSize',16)
axis tight 

subplot(2,1,2)
hold on
plot(timeCh1,agcCh1,'bo','MarkerSize',4,'MarkerFaceColor','b');
plot(EventNTTime,EventNTAGC,'ro','MarkerSize',4,'MarkerFaceColor','r');
%ylim([0 1.5])
xlim([start_time end_time])
ylabel('AGC Gain [dB] (NT1065)','FontSize',16)

xlabel('UTC Time, Local:UTC-7','FontSize',16)
samexaxis('join','yld',0.75);
[tick_loc,tick_label] = scale_x_axis(start_time,end_time);
set(gca, 'XTick', tick_loc); % Set x ticks to the tick locations
set(gca, 'xTickLabel', tick_label); % Set x tick labels to tick_label

axis tight

