function sbCoeff=sample2Byte(settings)
% Find the coefficient of samples per byte for different data types
%
% sbCoeff=sample2Byte(settings)
%   Inputs:
%       settings        - receiver settings. Type of data file, sampling
%                       frequency and the default filename are specified
%                       here.
%   Outputs:
%       sbCoeff         - samples per byte

dataType='schar';%settings.dataType;
% options: 'bit1','bit2,''bit4','schar','short','int','float','double'
if strcmp(dataType,'bit1')==1
    % 1 sample = 0.125 byte
    % This data type might bring slight discrepancies in ftell 
    % (recording absolute sample), fseek if the sample number is not in 
    % multiple of 8
    sbCoeff=0.125;
end
if strcmp(dataType,'bit2')==1
    % 1 sample = 0.25 byte
    % This data type might bring slight discrepancies in ftell 
    % (recording absolute sample), fseek if the sample number is not in 
    % multiple of 4
    sbCoeff=0.25;
end
if strcmp(dataType,'bit4')==1
    % 1 sample = 0.5 byte
    % This data type might bring slight discrepancies in ftell 
    % (recording absolute sample), fseek if the sample number is not in 
    % multiple of 2
    sbCoeff=0.5;
end
% 8 bits
if strcmp(dataType,'schar')==1
    % 1 sample = 1 byte
    sbCoeff=1;
end
% 16 bits
if strcmp(dataType,'short')==1
    % 1 sample = 2 byte
    sbCoeff=2;
end
% 32 bits
if strcmp(dataType,'int')==1
    % 1 sample = 4 byte
    sbCoeff=4;
end
% 32 bits
if strcmp(dataType,'float')==1
    % 1 sample = 4 byte
    sbCoeff=4;
end
% 64 bits
if strcmp(dataType,'double')==1
    % 1 sample = 8 byte
    sbCoeff=8;
end