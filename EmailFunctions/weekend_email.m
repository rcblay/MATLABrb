function weekend_email(logname,recipients,out_folder,folder,thresh,...
    pts_under_thrsh)

% Clear attachments in case they remain from previous email
clearvars attachments

end_time = unixtime(floor(clock)); % Serial date number
start_time = end_time - 7*86400;

attachments = gather_week_plots(out_folder,folder,start_time,end_time,...
    logname,thresh,pts_under_thrsh);


%% Set subject and body
subject = ['Weekly Email Report on ' logname ' System'];

bodystr = ['This is the ' logname ' system weekly report.',...
    ' Please see attached plots for data collected in last week.'];

body = bodystr;

%% Send AGC Email
sendemailAGC(recipients,subject,body,attachments)