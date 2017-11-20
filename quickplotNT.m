folder = '/mnt/admin/Brandon_Idaho/Night1/NT1065';

lenLog = 5;
thresh = [0 0 0 0];
pts_under_thrsh = [5 5 5 5];
channels = 1:4;

D = dir(folder);
nf = numel(D);

for i = 3:nf
    if D(i).isdir == 0
        file = D(i).name;
        out = char(file);
        datestring = out(lenLog+12:end-4);
        filename = conv_to_unixtime(datestring);
        start_time = filename; % Day collection began
        fid = fopen(char([folder, '/', file]));
        file = dir(char([folder, '/', file]));
        size = file.bytes;
        sizeMod = mod(size,14);
        size14 = size - sizeMod; % Size as rounded down to multiple of 14
        N = size14 / 14; % N represents number of rows of 14 bytes
        % Read in times, and register value
        times = fread(fid, N, 'uint64', 6); % SOMETHING WRONG
        fclose(fid);
        end_time = floor(start_time + times(end)/1e3 -times(1)/1000); % time since start----
        [Data] = AGC_PlottingNT(start_time, end_time,folder, ...
            ['/' out(1:lenLog) '_AGC_daily_*.bin'],thresh,pts_under_thrsh,...
            channels);
        for ii = 1:4
            LongvarNamePlotID = ['Data.Plot_ID_Ch' num2str(channels(ii))];
            varNamePlotID = ['Plot_ID_Ch' num2str(channels(ii))];
            plot_ID = Data.(varNamePlotID);
            if exist('plot_ID','var')
                set(plot_ID,'units','normalized','outerposition',[0 0 1 1]);
                saveas(plot_ID, [out_folder '/' logname '_DailyNT_Ch', ...
                    num2str(channels(ii)),'_',strdate, '.fig']);
                saveas(plot_ID, [out_folder '/' logname '_DailyNT_Ch', ...
                    num2str(channels(ii)),'_',strdate, '.jpg']);
                close(plot_ID);
            end
        end
        clear Data
    end
end