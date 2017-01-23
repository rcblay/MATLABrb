% init sets all parameters/settings and then runs background_loop which 
% reads in files and plots corresponding data 

%% Housekeeping
clearvars
close all
clc

%% Sets parameters
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

%% Set Initial Settings and Load in Calibration Data
initSettings;
load(calib_file); % Loads in steps_agc, & steps_atten from calibration.mat

%% Check for Existing Variables/Out Folder
% (1 = name(trig_value) is a variable in the workspace) 
if exist('trig_value','var')~=1 % var = kind (checks only for variables)
    trig_value = 0;
end
% If the folder out_folder doesn't exist (checks only for folders)
if ~exist(out_folder,'dir') 
    mkdir(out_folder); % Make new folder called out_folder
end

%% Runs File Analyzer Loop
background_loop;