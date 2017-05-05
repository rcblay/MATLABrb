function ENU = ECEF2ENU(lat,lon,XYZ)
%ECEF2ENU Conversion of ECEF coordinates (X,Y,Z) to ENU coordinates .
%
%Copyright (c) by Yafeng Li @ BIT ININ Lab
%Revision: 
%
% CVS record:
% $Id: ECEF2ENU.m,v 1.1.2.2 2016/04/26 11:42:59 dpl Exp $
%==========================================================================
ENU = [      -sin(lon)             cos(lon)          0;...
    -sin(lat)*cos(lon)   -sin(lat)*sin(lon)   cos(lat);...
     cos(lat)*cos(lon)    cos(lat)*sin(lon)   sin(lat) ]*XYZ;