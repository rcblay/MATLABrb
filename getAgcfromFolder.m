function [ntt,agc,file_list] = getAgcfromFolder(logname,t_start,t_end,folder)

D = dir(folder);

AGC_file_time_length = 3600*24;

file_list = {};
ntt = [];
agc = [];

for i = 3:numel(D)
    if(D(i).isdir) 
        continue;
    end
    [a,b] = regexp(D(i).name,[logname,'_AGC_(.)*.AGC.bin$'],'start','tokens');
    if(isempty(a))
        continue
    end
    file_date = str2double(b{1}{1});
    if((file_date<=t_start-AGC_file_time_length)||(file_date>=t_end))
        continue;
    end 
    
    %read it
    fid = fopen([folder,'/',D(i).name],'rb');
    data = fread(fid,'uint32');
    fclose(fid);
    if(isempty(data))
        continue;
    end
    tmp_tt = data(2:2:end);
    tmp_ntt = linspace(tmp_tt(1),tmp_tt(end),numel(tmp_tt))';
    tmp_agc = data(1:2:end)*3.3/4096;
    
    selected = (tmp_ntt>=t_start) & (tmp_ntt<=t_end);
    
    file_list = [file_list,D(i).name];
    agc = [agc;tmp_agc(selected)];
    ntt = [ntt;tmp_ntt(selected)];
    
end

if(isempty(ntt))
    return;
end
tmp = sortrows([ntt,agc],1);
agc = tmp(:,2);
ntt = tmp(:,1);