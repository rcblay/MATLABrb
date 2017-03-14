function data=mapBits(data,fileType)
% Map the value of bits for bit1 and bit2 type of data file
%   Inputs:
%       data            - data read from the data file
%       fileType        - file type
%   Outputs:
%       data            - mapped data
%
%  Bit2 Mapping
%  MSB  LSB     Read Value   Mapped Value
%   0    0         -2             -3
%   0    1         -1             -1
%   1    0          0             +1             
%   1    1         +1             +3 
%   Other - error
%
%  Bit1 Mapping
%     LSB       Read Value   Mapped Value
%      0            0             -1
%      1           +1             +1
%  Other - error

if strcmp(fileType,'bit2')==1
    % bit2 type
    for ii=1:length(data)
        switch data(ii)
            case -2
                data(ii)=-3;
            case -1
            case 0
                data(ii)=1;
            case 1
                data(ii)=3;
            otherwise
                disp('Error: file type is not bit2, check the file type');
                return;
        end
    end
end

if strcmp(fileType,'bit1')==1
    % bit2 type
    for ii=1:length(data)
        switch data(ii)
            case 0
                data(ii)=-1;
            case 1
            otherwise
                disp('Error: file type is not bit1, check the file type');
                return;
        end
    end
end