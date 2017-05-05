function outStr=adjustFormat(outStr,leng)
% Adjust the data format in rinex files
%
%  outStr=adjustFormat(outStr,leng)
%
%   Inputs:
%       outStr               - input data stream
%       leng                 - length of the data stream
%   outputs:
%       outStr               - modified input data stream (output data stream)

% Replace the + sign with a space
outStr= strrep(outStr,' +','  ');
% Change Exponential sign from E to D and reduce the number of digits after E
outStr= strrep(outStr,'E+0','D+');
outStr= strrep(outStr,'E-0','D-');
posIndex = strfind(outStr,'D');
for ind=posIndex
    if (str2double(outStr(1:ind-1))==0)
        % data is zero just change the postion of the decimal
        index=find(outStr=='.');
        outStr(index) = outStr(index-1);
        outStr(index-1) = '.';
    else
        %change the postion of the decimal
        index=find(outStr=='.');
        outStr(index) = outStr(index-1);
        outStr(index-1)='.';
        
        if(outStr(ind+1)=='+')
            %increment the number after D+
            outStr(ind+2:ind+3)=sprintf('%02d',str2num(outStr(ind+2:ind+3))+1);
        else
            %Decrement the number after D-
            outStr(ind+2:ind+3)=sprintf('%02d',str2num(outStr(ind+2:ind+3))-1);
        end
    end
end

if length(outStr)~=leng
    for ii=1:leng-length(outStr)
        outStr=[' ',outStr];
    end
end