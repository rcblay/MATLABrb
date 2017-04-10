function [CNo_val,CNo_ind] = findTrackResultsNT1065(filename,desiredSec)

% Then, it is run through the SDR code and TrackResults is returned.

initSettings();
settings.fileName           = filename;
settings.msToProcess = (floor(desiredSec)-0.1)*1000;
settings.IF                 = 60e3;      %[Hz]
settings.samplingFreq       = 6.625e6;     %[Hz]
init_tracking;

CNo_val = trackResults.CNo.VSMValue;
CNo_ind = trackResults.CNo.VSMIndex;

close all;