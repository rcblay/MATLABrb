% init sets all parameters/settings and then runs background_loop which 
% reads in files and plots corresponding data 

%% Housekeeping
clearvars
close all
clc

%% Adds Folders to Path
addpaths;

%% Sets parameters
folder = '/home/dma/Documents/CUvsSUcompare/data/CU_SiGe_1';
out_folder = [folder,'/figures'];
activate_IF_generation = 1; % Flag used to plot spectrum plots
grow_check = 1; % Check if file is still growing
period = 86400.0; % Time to pause to take data
calib_file = 'calibration.mat';
sampling_freq =  8.183800e6;
logname = 'CU'; %'rec'
localUTC = 17;

%% Automated Email Settings
recipients = {'rcblay@gmail.com'};%,'dma@colorado.edu'};
emailtrig = 1;
weekend_email = 1;

%% Trigger Settings
thresh = 0.9; % Voltage threshold
pts_under_thrsh = 5; % # of pts under threshold that constitutes a trigger

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