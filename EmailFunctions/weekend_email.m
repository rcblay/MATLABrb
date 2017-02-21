function weekend_email(logname,recipients,directory)

% Clear attachments in case they remain from previous email
clearvars attachments

end_time = now; % Serial date number
start_time = end_time - 7;

attachments = gather_week_plots(directory,start_time,end_time);


%% Set subject and body
subject = ['Weekly Email Report on ' logname ' System'];

bodystr = ['This is the ' logname ' system weekly report.',...
    'Please see attached plots for all plots created/modified in last week.'];

body = bodystr;

%% Send AGC Email
sendemailAGC(recipients,subject,body,attachments)