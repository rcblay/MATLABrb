% init sets all parameters/settings and then runs background_loop which 
% reads in files and plots corresponding data 

%% Housekeeping
clearvars
close all
clc

%% Adds Folders to Path
addpaths;

%% Sets parameters
% Make sure to change initSettings if needed
folder = '/mnt/admin/Brandon_Idaho/Night1/NT1065';
out_folder = [folder,'/figures'];
activate_IF_generation = 0; % Flag used to plot spectrum plots
grow_check = 0; % Check if file is still growing
is_data_logging = 0; % Should data still be logging?
calib_file = 'calibration.mat'; % DIFFERENT FOR NT1065 but how?
logname = 'Idaho'; %'rec'
localUTC = 2;
Ahead_Behind = 1; % Ahead of UTC = 1 (Korea), Behind UTC = 0 (Boulder)

%% Automated Email Settings
recipients = {'rcblay@gmail.com','dma@colorado.edu'};
emailtrig = 0;
weekendemail = 0;

%% Channel/Trigger Settings
channels = [1 2 3 4]; % Must match # of elements in thresh/pts_under_thrsh
thresh = [42 42 42 42]; % Voltage threshold
pts_under_thrsh = [5 5 5 5]; % # of pts under thresh to constitute trigger

%% Set Initial Settings and Load in Calibration Data
initSettings;
%load(calib_file); % Loads in steps_agc, & steps_atten from calibration.mat

%% Check for Existing Variables/Out Folder
% If the folder out_folder doesn't exist (checks only for folders)
if ~exist(out_folder,'dir') 
    mkdir(out_folder); % Make new folder called out_folder
end

%% Runs File Analyzer Loop
background_loopNT;