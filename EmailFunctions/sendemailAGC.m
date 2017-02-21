function sendemailAGC(recipients,subject,body,attachments)
%% Send Mail to predetermined recipients
% Inputs:
%   -recipients (of email) [email addresses]
%   -subject (of email)
%   -body (of email)
%   -attachments (of email)

mail = 'agcmonitor@gmail.com';
password = 'il1keGnss';
server = 'smtp.gmail.com';
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server',server);
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', ...
    'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');
% Send mail

if isempty(attachments)
    disp('No attachments');
    sendmail(recipients,subject,body);
else
    disp('Attachments');
    sendmail(recipients,subject,body,attachments);
end