fclose all; 
% close all;

%update this line with the latest file created in /home/cnsl-linux/Jammer/data
fid=fopen('/home/minty/Desktop/Ksenia/Data/CU_AGC_1473533864.AGC.bin','rb');


data = fread(fid,'uint32');
agc = data(1:2:end)*3.3/4096;
plot(agc)


time=data(2:2:end-1);
figure
plot(time)

% %assume full 24 set, approximate Fs
% fs1=size(agc2,1)/(60*60*24);  %but this is odd, like 93sps - is it really 24 hours
% fs2=(data(end)-data(2))/(60*60*24);
% 
% timev=data(2):1/fs1:data(end);  %should be about the same length
% 
% figure(100)

% plot(timev(1:4:length(agc)), agc(1:4:end),'c.')
% hold on
% plot(timev(1:4:length(agc)), agc(1:4:end),'m')
% axis tight;grid;
% xt = get(gca,'XTick');
% set(gca,'XTickLabel', sprintf('%.1f|',xt))

