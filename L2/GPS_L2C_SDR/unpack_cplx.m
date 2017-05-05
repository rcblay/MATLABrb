function unpack_cplx(filename_in,filename_out)

fid = fopen(filename_in,'rb');
fid_out = fopen(filename_out,'wb');

piece = 4e6;
fseek(fid,0,1);
nword = (ftell(fid));
fseek(fid,0,-1);

nl = ceil(nword/piece);

h = waitbar(0,['Converting...']);

LUT_I_long1 = [1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3;1;-1;1;-1;3;-3;3;-3];
LUT_I_long2 = [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3];
LUT_Q_long1 = [1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3;1;1;-1;-1;1;1;-1;-1;3;3;-3;-3;3;3;-3;-3];
LUT_Q_long2 = [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;-1;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3;-3];

for n = 0:nl-1
    npiece = min(piece,nword-n*piece);
    
    data = fread(fid, npiece,'uint8'); % read the data from the opened file - fid
    
    data_2file = zeros(4*numel(data),1);

    data_2file(1:4:end) = LUT_I_long1(data+1);
    data_2file(2:4:end) = LUT_Q_long1(data+1);
    data_2file(3:4:end) = LUT_I_long2(data+1);
    data_2file(4:4:end) = LUT_Q_long2(data+1);
    
    fwrite(fid_out,data_2file,'schar');
    
    waitbar((n+1)/(nl),h);
end

fclose(fid);
fclose(fid_out);
close(h);