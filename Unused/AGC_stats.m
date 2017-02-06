folder = '/home/gnss/Desktop/SUJammer';%'/home/gnss/Jammer/data';

cmd_line = sprintf('ls %s|grep -E "^(.+)_AGC_([0-9]+).AGC.bin$" | tail -1',folder);
[s,tmp] = system(cmd_line);
agc_filename = strtrim(tmp);

fid = fopen([folder,'/',agc_filename],'rb');

data = fread(fid,'uint32');
agc = data(1:2:end)*3.3/4096;

m_agc = mean(agc);
s_agc = std(agc);
min_agc = min(agc);
max_agc = max(agc);

cmd_line = sprintf('echo "FILE=%s AVG=%f STD=%f MIN=%f MAX=%f" >> AGC_stats',agc_filename,m_agc,s_agc,min_agc,max_agc);
system(cmd_line);
