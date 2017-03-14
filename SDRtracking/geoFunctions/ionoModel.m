function iono = ionoModel(almanac,az,el,TOW,pos)
% Calculation of an Ionospheric range correction for the GPS L1 frequency 
% from the parameters broadcasted in the GPS Navigation Message 
% (Klobuchar model).
% References:                                                     
% Parkinson, Spilker (ed), "Global Positioning System Theory and 
% Applications, pp.513-514.                                     
% ICD-GPS-200, Rev. C, (1997), pp. 125-128 
%
%  iono = ionoModel(almanac,az,el,TOW,pos)
%
%   Inputs:
%       almanac           - ionospheric correction parameters from
%                           almanac of the satellites
%       az                - Geodetic azimuth of the satellite (degrees)
%       el                - Elevation angle of the satellite (degrees)
%       TOW               - GPS time for the receiver
%       pos               - ECEF coordinate for the receiver (meters)
%   Outputs:
%       iono              - ionospheric error of the satellite (seconds)

% degees to semi-circles
deg2semi =  1.0/180.0;
% azimuth in  semi-circles
az = az*deg2semi; 
% elevation angle in semi-circles
el = el*deg2semi;

% check if the ionospheric correction parameters are decoded
if almanac.a0==0
    iono=0;
else
    if any(pos~=0)==0
        phi_u=0;
        lambda_u=0;
    else
        % obtain the user position in WGS84 frame
        [phi_u, lambda_u] = cart2geo(pos(1),pos(2),pos(3),5);
        phi_u=phi_u*deg2semi;
        lambda_u=lambda_u*deg2semi;
    end
    % Earth's central angle between the user position and the earth projection
    % of ionospheric intersection point (semi-circles)
    psi = 0.0137 / (el+0.11) - 0.022;
    % Subionospheric latitude
    phi_i=phi_u+psi*cos(az);  
    if phi_i>0.416
        phi_i=0.416;
    end
    if phi_i<-0.416
        phi_i=-0.416;
    end
    
    % Subionospheric longitude
    lambda_i=lambda_u+psi*sin(az)/cos(phi_i);
    % Geomagnetic latitude
    phi_m=phi_i+0.064*cos(lambda_i-1.617);  % semi-circles
    
    % Seconds of day
    t=4.32e4*lambda_i+TOW;
    if t>=86400
        t=t-86400;
    else
        if t<0
            t=t+86400;
        end
    end
    % Obliquity factor
    F=1.0+16.0*(0.53-el)^3;
    % Period of model
    PER=almanac.beta0+almanac.beta1*phi_m+...
        almanac.beta2*phi_m^2+almanac.beta3*phi_m^3;  % seconds
    if PER < 72000
        PER=72000; % seconds
    end
    % Phase of the model
    x=2*pi*(t-50400)/PER; % radians
    % Amplitude of the model
    AMP=almanac.a0+almanac.a1*phi_m+...
        almanac.a2*phi_m^2+almanac.a3*phi_m^3;   % seconds
    if AMP <0
        AMP=0;  % seconds
    end
    % Ionospheric corr
    if abs(x)<1.57
        iono=F*(5.0e-9+AMP*(1-(x^2)/2+(x^4)/24)); % seconds
    else
        iono=F*(5.0e-9); % seconds
    end
    
end


