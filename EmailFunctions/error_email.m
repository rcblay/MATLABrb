function error_email(logname,recipients,directory)

% Clear attachments in case they remain from previous email
clearvars attachments

attachments = {};

% Find time when directory last modified
a = dir(directory);
serial_time = a(1).datenum; % Datenum of '.' (or current folder)
time = datestr(serial_time);

%% Set subject and body
subject = ['Error Email Report on ' logname ' System'];

bodystr = ['AGC file stopped growing at ' time];

body = bodystr;

%% Send AGC Email
sendemailAGC(recipients,subject,body,attachments)