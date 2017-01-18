function eph = initEph(settings)
% Initialize the ephemeris data structure
%
%  eph = initEph(settings)
%
%   Inputs:
%
%       settings          - receiver settings.
%   Outputs:
%       eph.nav           - navigation message
%       eph.almanac       - ionospheric and UTC parameters


% The ephemeris is updated every 2 hours
% No matter how short the data is, still consider there is one updates in
% the data
% Estimate the number of ephemeris records
numOfEphRec=ceil(settings.msToProcess/(2*3600*1000))+1;

% contents in subframe 1
eph.nav.TOW        =0;
eph.nav.weekNumber =0;
eph.nav.accuracy   =0;
eph.nav.health     =0;
eph.nav.T_GD       =0;
eph.nav.IODC       =0;
eph.nav.t_oc       =0;
eph.nav.a_f2       =0;
eph.nav.a_f1       =0;
eph.nav.a_f0       =0;
% contents in subframe 2
eph.nav.IODE_sf2   =0;
eph.nav.C_rs       =0;
eph.nav.deltan     =0;
eph.nav.M_0        =0;
eph.nav.C_uc       =0;
eph.nav.e          =0;
eph.nav.C_us       =0;
eph.nav.sqrtA      =0;
eph.nav.t_oe       =0;
% contents in subframe 3
eph.nav.C_ic       =0;
eph.nav.omega_0    =0;
eph.nav.C_is       =0;
eph.nav.i_0        =0;
eph.nav.C_rc       =0;
eph.nav.omega      =0;
eph.nav.omegaDot   =0;
eph.nav.IODE_sf3   =0;
eph.nav.iDot       =0;

% contents in page 18, subframe 4
% Update every 6 days
eph.almanac.dataID     =0;
eph.almanac.svID       =0;
% Ionospheric model parameters
eph.almanac.a0         =0;
eph.almanac.a1         =0;
eph.almanac.a2         =0;
eph.almanac.a3         =0;
eph.almanac.beta0      =0;
eph.almanac.beta1      =0;
eph.almanac.beta2      =0;
eph.almanac.beta3      =0;
% UTC parameters
eph.almanac.A0         =0;
eph.almanac.A1         =0;
eph.almanac.deltaTls   =0;
eph.almanac.t_ot       =0;
eph.almanac.WNt        =0;
eph.almanac.WNlsf      =0;
eph.almanac.DN         =0;
eph.almanac.deltaTlsf  =0;

eph.nav=repmat(eph.nav, numOfEphRec, 32);