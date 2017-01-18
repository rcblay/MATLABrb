% plotCUvsNT1065vsSU plots the same time range of data from CU and NT1065 
% and SU on the same plot.

%% Housekeeping
clearvars
close all
clc

%% Parameters for Time Range
start_time = unixtime([2016 12 24 0 0 0]);
end_time = start_time + 4*86400 - 1;

%% CU
directory = '/home/dma/Documents/CUvsSUcompare/data/SiGeData';
x_tick_location = 1; % Daily
logname = 'CU';
file_name = ['/*' logname '_AGC*AGC.bin'];
[CU_plot_fid, CU_plotted_time, CU_plotted_agc] = AGC_Plotting(start_time...
    , end_time,  directory, file_name, x_tick_location,logname);
close(CU_plot_fid);

%% Nt1065
filename = '/home/dma/Documents/regdump.bin';
Channels = 1;
timerange = [0 96];
TimeStart = 0;
Day = 0;

[time_k2, ApproxGain3,RF_GainSt3] = parseFileAGC2(filename,Channels,timerange,...
    TimeStart,Day);

%% Stanford
directory = '/home/dma/Documents/CUvsSUcompare/data/SUdata';
x_tick_location = 1; % Daily
logname = 'SU';
file_name = ['/*' logname '_AGC*AGC.bin'];
[SU_plot_fid, SU_plotted_time, SU_plotted_agc] = AGC_Plotting(start_time...
    , end_time, directory, file_name, x_tick_location,logname);
close(SU_plot_fid);

%% Plot
figure;
hold on
subplot(3,1,1)
plot(SU_plotted_time,SU_plotted_agc,'ro','MarkerSize',4,'MarkerFaceColor','r');
ylim([0 1.5])
xlim([start_time end_time])
ylabel('AGC Value [V] (SU)')
title('SU vs CU vs NT1065 (CU)')

subplot(3,1,2)
plot(CU_plotted_time,CU_plotted_agc,'go','MarkerSize',4,'MarkerFaceColor','g');
ylim([0 1.5])
xlim([start_time end_time])
ylabel('AGC Value [V] (CU)')

subplot(3,1,3)
plot(time_k2(:,1)*3600 + start_time,ApproxGain3(:,1));
plot(time_k2(:,1)*3600 + start_time,RF_GainSt3(:,1));
ylim([0 50])
xlim([start_time end_time])
ylabel('Gain [dB] (CU NT1065)')
legend('IF Gain','RF Gain')

xlabel('UTC Time')
samexaxis('join','yld',0.75);



