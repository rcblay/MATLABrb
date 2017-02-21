function attachments = gather_week_plots(directory,start_time,end_time)
% This function gets all the files for the past week and returns them in
% attachments.

% start_time and end_time are in serial time. 
attachments = {};
j =  1;
files = dir(directory);
for i = 3:length(files)
   if files(i).datenum > start_time && files(i).datenum < end_time
      filenames{j} = [directory '/' files(i).name];
      j = j + 1;
   end
end
% Have to get only jpg
m = 1;
if exist('filenames','var')
    for k = 1:length(filenames)
        ext = filenames{k}(end-2:end);
        if strcmp('jpg',ext)
            attachments{m} = filenames{k};
            m = m + 1;
        end
    end
end

end