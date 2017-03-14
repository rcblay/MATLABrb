% init sets all parameters/settings and then runs background_loop which 
% reads in files and plots corresponding data 

%% Housekeeping
clearvars
close all
clc

%% Adds Folders to Path
addpaths;

%% Sets parameters
<<<<<<< HEAD
% Make sure to change initSettings if needed
folder = '/home/dma/Documents/CUvsSUcompare/data/CU_SiGe_1';
=======
folder = '/home/gnss/SiGe/Sean_SiGe_Stuff/data';
>>>>>>> e18c0b06bf44ea4873a6daec397609a0dadb5a3d
out_folder = [folder,'/figures'];
activate_IF_generation = 1; % Flag used to plot spectrum plots
grow_check = 1; % Check if file is still growing
is_data_logging = 1; % Should data still be logging?
calib_file = 'calibration.mat';
logname = 'CU'; %'rec'
localUTC = 18;
Ahead_Behind = 0; % Ahead of UTC = 1 (Korea), Behind UTC = 0 (Boulder)

%% Automated Email Settings
recipients = {'rcblay@gmail.com','dma@colorado.edu'};
emailtrig = 1;
weekendemail = 1;

%% Trigger Settings
thresh = 0.9; % Voltage threshold
pts_under_thrsh = 5; % # of pts under threshold that constitutes a trigger

%% Set Initial Settings and Load in Calibration Data
initSettings;
load(calib_file); % Loads in steps_agc, & steps_atten from calibration.mat

%% Check for Existing Variables/Out Folder
% If the folder out_folder doesn't exist (checks only for folders)
if ~exist(out_folder,'dir') 
    mkdir(out_folder); % Make new folder called out_folder
end

%% Runs File Analyzer Loop
background_loop;