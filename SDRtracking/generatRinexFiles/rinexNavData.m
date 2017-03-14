function rinexNavData(fid,rinexData)
% Write rinex nav file
%
%  rinexNavData(fid,eph)
%
%   Inputs:
%       fid               - file ID
%       rinexData         - Rinex data structure

numOfEph=size(rinexData.channel(1).eph,1);

for jj=1:numOfEph
    for ii=1:size(rinexData.PRNlist,2)
        eph=rinexData.channel(ii).eph(jj,:);
        % if there are valid records
        if eph.IODC~=0
            calcTime= calcDateTime(eph.weekNumber,eph.t_oc);
            PRN     = num2str(rinexData.PRNlist(ii));
            year    = num2str(calcTime.year);
            year    = year(3:4);
            month   = num2str(calcTime.month);
            day     = num2str(calcTime.day);
            hour    = num2str(calcTime.hour);
            minute  = num2str(calcTime.minute);
            second  = calcTime.second;
            
            %% Output1-- PRN / EPOCH / SV CLK
            outStr0 = sprintf('%2s %s %2s %2s %2s %2s %4.1f %+19.11E %+19.11E %+19.11E\n',...
                PRN,year,month,day,hour,minute,second,eph.a_f0,eph.a_f1,eph.a_f2);
            
            %% Output2-- IODE Issue of Data/Crs/Delta n/M0
            outStr1 = sprintf('    %+19.11E %+19.11E %+19.11E %+19.11E\n',...
                eph.IODE_sf2,eph.C_rs,eph.deltan,eph.M_0);
            
            %% Output3-- Cuc/e Eccentricity/Cus/sqrt(A)
            outStr2 = sprintf('    %+19.11E %+19.11E %+19.11E %+19.11E\n',...
                eph.C_uc,eph.e,eph.C_us,eph.sqrtA);
            
            %% Output4-- Toe/Cic/OMEGA/CIS
            outStr3 = sprintf('    %+19.11E %+19.11E %+19.11E %+19.11E\n',...
                eph.t_oe,eph.C_ic,eph.omega_0,eph.C_is);
            
            %% Output5-- i0/Crc/omega/OMEGA DOT
            outStr4 = sprintf('    %+19.11E %+19.11E %+19.11E %+19.11E\n',...
                eph.i_0,eph.C_rc,eph.omega,eph.omegaDot);
            
            %% Output6-- IDOT/Codes on L2 channel/GPS Week/L2 P
            outStr5 = sprintf('    %+19.11E %+19.11E %+19.11E %+19.11E\n',...
                eph.iDot,0,eph.weekNumber,0); %The parameter after iDot is Codes on L2C,%The parameter after weeknumber is L2 P data flag
            
            %% Output7-- SV accuracy/SV health/TGD/IODC Issue of Data
            outStr6 = sprintf('    %+19.11E %+19.11E %+19.11E %+19.11E\n',...
                eph.accuracy,eph.health,eph.T_GD,eph.IODC); 
            
            %% Here is updated every 30 seconds
            outStr7 = sprintf('    %+19.11E %+19.11E\n',...
                eph.TOW,0);%Transmission Time, Fit Interval, spare, spare
            
            outStr = sprintf('%s%s%s%s%s%s%s%s',outStr0,outStr1,outStr2,outStr3,outStr4,outStr5,outStr6,outStr7);
            
            % Replace the + sign with a space
            outStr= strrep(outStr,' +','  ');
            % Change Exponential sign from E to D and reduce the number of digits after E
            outStr= strrep(outStr,'E+0','D+');
            outStr= strrep(outStr,'E-0','D-');
            
            % Adjust the format. Eg. 2.95200000000D+05 should be changed to
            % .295200000000D+06 and 9.56852873266D-01 should be changed to
            % .956852873266D-00
            
            posIndex = strfind(outStr,'D');
            
            for ind=posIndex
                if (str2double(outStr(ind-13:ind-1))==0)
                    %just change the postion of the decimal
                    outStr(ind-12) = outStr(ind-13);
                    outStr(ind-13) = '.';
                else
                    %change the postion of the decimal
                    outStr(ind-12) = outStr(ind-13);
                    outStr(ind-13) = '.';
                    
                    if(outStr(ind+1)=='+')
                        %increment the number after D+
                        outStr(ind+2:ind+3)=sprintf('%02d',str2num(outStr(ind+2:ind+3))+1);
                    else
                        %Decrement the number after D-
                        outStr(ind+2:ind+3)=sprintf('%02d',str2num(outStr(ind+2:ind+3))-1);
                    end
                end
            end
            
            fprintf(fid,'%s',outStr);
        end
    end
    
end
