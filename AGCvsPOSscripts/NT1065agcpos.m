%% Read in Data
fid = fopen('AGCSiGe.bin','r');
AGC_SiGe = fread(fid,'double');
fid = fopen('TimeSiGe.bin','r');
Time_SiGe = fread(fid,'double');
fid = fopen('agcNT_ch1.bin');
agc_ch1 = fread(fid,'double');
fid2 = fopen('agcNT_ch2.bin');
agc_ch2 = fread(fid2,'double');
fid3 = fopen('agcNT_ch3.bin');
agc_ch3 = fread(fid3,'double');
fid4 = fopen('agcNT_ch4.bin');
agc_ch4 = fread(fid4,'double');
fid5 = fopen('timeNT_ch1.bin');
time_ch1 = fread(fid5,'double');
fid6 = fopen('timeNT_ch2.bin');
time_ch2 = fread(fid6,'double');
fid7 = fopen('timeNT_ch3.bin');
time_ch3 = fread(fid7,'double');
fid8 = fopen('timeNT_ch4.bin');
time_ch4 = fread(fid8,'double');
fid = fopen('LatTruth.bin','r');
Lat = fread(fid,'double');
fid = fopen('LongTruth.bin','r');
Long = fread(fid,'double');
fid = fopen('TimeTruth.bin','r');
Time_Truth = fread(fid,'double');
fclose all;

index = find(Lat == 0);
Lat(index) = [];
Long(index) = [];
Time_Truth(index) = [];

time_start = Time_SiGe(1);
ind = find(Time_Truth >= time_start);
Time_Truth2 = Time_Truth(ind);
Lat2 = Lat(ind);
Long2 = Long(ind);

%% Change Data format of time
time_ch1 = time_ch1*3600;
time_ch2 = time_ch2*3600;
time_ch3 = time_ch3*3600;
time_ch4 = time_ch4*3600;
firsttime = unixtime([2017 3 4 0 0 0]);

time_ch1 = time_ch1 + firsttime;
time_ch2 = time_ch2 + firsttime;
time_ch3 = time_ch3 + firsttime;
time_ch4 = time_ch4 + firsttime;

%%

ind2 = find(time_ch1 >= time_start);
time_ch1 = time_ch1(ind2);
agc_ch1 = agc_ch1(ind2);
ind3 = find(time_ch2 >= time_start);
time_ch2 = time_ch2(ind3);
agc_ch2 = agc_ch2(ind3);
ind4 = find(time_ch3 >= time_start);
time_ch3 = time_ch3(ind4);
agc_ch3 = agc_ch3(ind4);
ind5 = find(time_ch4 >= time_start);
time_ch4 = time_ch4(ind5);
agc_ch4 = agc_ch4(ind5);

%%
analyze = agc_ch4;

for i = 1:length(analyze)
    
    if i == length(analyze)
        Lat4(i) = Lat4(i-1);
        Long4(i) = Long4(i-1);
        break;
    end

    index2 = find(Time_Truth2 <= time_ch1(i));
    ind = index2(end);
    beforetime = Time_Truth2(ind);
    beforelat = Lat2(ind);
    beforelong = Long2(ind);
    ind2 = ind + 1;
    aftertime = Time_Truth2(ind2);
    afterlat = Lat2(ind2);
    afterlong = Long2(ind2);
    
    
    Lat4(i) = ((afterlat - beforelat)/(aftertime - beforetime))*...
        (time_ch1(i) - beforetime) + beforelat;
    Long4(i) = ((afterlong - beforelong)/(aftertime - beforetime))*...
        (time_ch1(i) - beforetime) + beforelong;
    
end

Lat4 = Lat4';
Long4 = Long4';
%%
indBIG = find(analyze < 41);
AGCbig = analyze(indBIG);
Longbig = Long4(indBIG);
Latbig = Lat4(indBIG);

indHUGE = find(analyze < 36);
AGChuge = analyze(indHUGE);
Longhuge = Long4(indHUGE);
Lathuge = Lat4(indHUGE);

%% potentially plot triggers
figure;
hold on
scatter(Long4,Lat4,10,analyze,'filled')
scatter(Longbig,Latbig,50,AGCbig,'filled')
scatter(Longhuge,Lathuge,100,AGChuge,'filled')
colormap('cool')
caxis([min(analyze) max(analyze)])
plot_google_map;