%% Read in All Data

fid = fopen('AGCSiGe.bin','r');
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

scatter(-Lat,-Long,10,Time_Truth)
title('Position with Time Colored')

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

for i = 1:length(AGC_SiGe2)
    
    if i == length(AGC_SiGe2)
        Lat4(i) = Lat4(i-1);
        Long4(i) = Long4(i-1);
        break;
    end

    index2 = find(Time_Truth2 <= Time_SiGe2(i));
    ind = index2(end);
    beforetime = Time_Truth2(ind);
    beforelat = Lat2(ind);
    beforelong = Long2(ind);
    ind2 = ind + 1;
    aftertime = Time_Truth2(ind2);
    afterlat = Lat2(ind2);
    afterlong = Long2(ind2);
    
    
    Lat4(i) = ((afterlat - beforelat)/(aftertime - beforetime))*...
        (Time_SiGe2(i) - beforetime) + beforelat;
    Long4(i) = ((afterlong - beforelong)/(aftertime - beforetime))*...
        (Time_SiGe2(i) - beforetime) + beforelong;
    
    
end

Lat4 = Lat4';
Long4 = Long4';
%%
ind = find(AGC_SiGe2 < 0.7);
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

Long4event = Long4(ind9);
Lat4event = Lat4(ind9);
AGCevent = AGC_SiGe2(ind9);
Timeevent = Time_SiGe2(ind9);

figure(2);
hold on
scatter(Long4,Lat4,10,AGC_SiGe2)
plot(Long4event,Lat4event,'xr','LineWidth',2,'MarkerSize',20)
caxis([0.6 0.85])
colormap('cool')
plot_google_map;
