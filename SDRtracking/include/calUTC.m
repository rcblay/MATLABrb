function  utcTime=calUTC(almanac,gpsTime,WN)
% Calcuate UTC time from GPS time based on broadcast almanac
%
% utcTime=calUTC(almanac,gpsTime,WN)
%   Inputs:
%       almanac         - UTC parameters
%       gpsTime         - GPS time of week
%       WN              - GPS week number
%   Outputs:
%       utcTime         - UTC time of week

tLSF=almanac.WNlsf*604800+almanac.DN*86400;
tGPS=almanac.WNt*604800+gpsTime;

dnGPS=gpsTime/86400;
dtimeSpan=mod([almanac.DN+3/4,almanac.DN+5/4],7);

% relationship a
if tGPS < tLSF 
    delta_utcTime=almanac.deltaTls+almanac.A0+...
        almanac.A1*(gpsTime-almanac.t_ot+604800*(WN-almanac.WNt));
    % relationship a
    if (dnGPS > dtimeSpan(2)|| dnGPS < dtimeSpan(1))
        utcTime=mod(gpsTime-delta_utcTime,86400);
    else
        % relationship b
        W = mod((gpsTime-delta_utcTime-43200),86400)+43200;
        utcTime=mod(W,86400+almanac.deltaTlsf-almanac.deltaTls);
    end
else
    % relationship c
    delta_utcTime=almanac.deltaTlsf+almanac.A0+...
        almanac.A1*(gpsTime-almanac.t_ot+604800*(WN-almanac.WNt));
    utcTime=mod(gpsTime-delta_utcTime,86400);
end




