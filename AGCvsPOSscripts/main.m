%% Read in All Data

fid = fopen('smoothedAGC.bin','r');
AGC_SiGe = fread(fid,'double');
fid = fopen('TimeSiGe.bin','r');
Time_SiGe = fread(fid,'double');
fid = fopen('LatTruth.bin','r');
Lat = fread(fid,'double');
fid = fopen('LongTruth.bin','r');
Long = fread(fid,'double');
fid = fopen('TimeTruth.bin','r');
Time_Truth = fread(fid,'double');
fclose('all');

%% Remove Outliers

index = find(Lat == 0);
Lat(index) = [];
Long(index) = [];
Time_Truth(index) = [];

%% Plot Lat, Long and Time

scatter(Long,Lat,10,Time_Truth)
title('Position with Time Colored')
plot_google_map;

%% Start Organizing the Data

time_start = Time_SiGe(1);
ind = find(Time_Truth >= time_start);
Time_Truth2 = Time_Truth(ind);
Lat2 = Lat(ind);
Long2 = Long(ind);

time_end = Time_Truth2(end);
ind = find(Time_SiGe <= time_end);
AGC_SiGe2 = AGC_SiGe(ind);
Time_SiGe2 = Time_SiGe(ind);

for i = 1:length(Time_Truth2)
    
    if i == length(Time_Truth2)
        AGC4(i) = Lat2(i-1);
        break;
    end

    index2 = find(Time_SiGe2 <= Time_Truth2(i));
    ind = index2(end);
    beforetime = Time_SiGe2(ind);
    beforeagc = AGC_SiGe2(ind);
    ind2 = ind + 1;
    aftertime = Time_SiGe2(ind2);
    afteragc = AGC_SiGe2(ind2);
    
    
    AGC4(i) = ((afteragc - beforeagc)/(aftertime - beforetime))*...
        (Time_Truth2(i) - beforetime) + beforeagc;
    
end

AGC4 = AGC4';
%%
ind = find(AGC4 < 0.7);
a = diff(ind);
ind2 = find(a == 1);
ind3 = ind(ind2);
b = diff(ind3);
ind4 = find(b == 1);
ind5 = ind3(ind4);
c = diff(ind5);
ind6 = find(c == 1);
ind7 = ind5(ind6);
d = diff(ind7);
ind8 = find(d == 1);
ind9 = ind7(ind8);

Long4event = Long2(ind9);
Lat4event = Lat2(ind9);
AGCevent = AGC4(ind9);
Timeevent = Time_Truth2(ind9);

%%
indBIG = find(AGC4 < 0.8);
AGCbig = AGC4(indBIG);
Longbig = Long2(indBIG);
Latbig = Lat2(indBIG);

indHUGE = find(AGC4 < 0.7);
AGChuge = AGC4(indHUGE);
Longhuge = Long2(indHUGE);
Lathuge = Lat2(indHUGE);


%%

figure(2);
hold on
scatter(Long2,Lat2,10,AGC4,'filled')
scatter(Longbig,Latbig,50,AGCbig,'filled')
scatter(Longhuge,Lathuge,100,AGChuge,'filled')
plot(Long4event,Lat4event,'xb','LineWidth',2,'MarkerSize',20)
caxis([0.6 0.85])
colormap('cool')
plot_google_map;
