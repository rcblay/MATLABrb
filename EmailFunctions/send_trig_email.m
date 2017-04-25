function send_trig_email(time,logname,attachments,recipients)

subject = ['AGC Trigger Detected on ' logname ' System at ' time...
    ' UTC'];

bodystr = ['On the ' logname ' system, a trigger was detected at ' time...
    ' UTC. Please see attached plots.'];

body = bodystr;

%% Send AGC Email
sendemailAGC(recipients,subject,body,attachments)

end