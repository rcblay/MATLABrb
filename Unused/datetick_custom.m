function datetick_custom( haxe , varargin )
% datetick_custom( haxe [, TimeZone])
%variable-length input arguement list = varargin

    if length(varargin)==0
        %get java object to get time zone
        import java.util.*;
        c = Calendar.getInstance();
        z = c.getTimeZone();
    else
        z = varargin{1};
    end
    
    ticks = get(haxe,'XTick');
    ticks_label = {};
    
    for i=1:numel(ticks)
        dn_utc = datenum([1970 1 1 0 0 ticks(i)]);
        dn_local = datenum([1970 1 1 0 0 ticks(i)+z.getOffset(ticks(i)*1000)/1000]);
        ticks_label = [ticks_label,[datestr(dn_utc,'HH:MM'),' (',datestr(dn_local,'HH:MM'),')']];
    end

    set(haxe,'XTickLabe',ticks_label);
    
end