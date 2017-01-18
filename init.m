%found where folder and out_folder are defined and it didn't work because
%we are in a different folder now. We also don't have '/figures' 

folder = '/home/dma/Documents/CUvsSUcompare/data/CU_SiGe_1'; %'/home/minty/Desktop/Ksenia/Data';
out_folder = [folder,'/figures'];
activate_matlab_fig = 0;
activate_IF_generation = 1;
period = 86400.0;
calib_file = 'calibration.mat';
sampling_freq =  8.183800e6;
threshold = 0.95;
logname = 'CU'; %'rec'

%Time zone
use_local_timezone = 1; %1-AUTO 0-MANUAL
%if 0 indicate an other timezone ID, examples : 
% for Boulder,CO : 'US/Mountain'
% for Stanford,CA : 'US/Pacific'
% for Taiwan : 'Asia/Taipei'
local_zone = 'US/Mountain';

import java.util.*;
if use_local_timezone==1
    c = Calendar.getInstance();
    z = c.getTimeZone();
else
    z = TimeZone.getTimeZone(local_zone);
end
