function [F,T,P] = spectro(filename_in,nf,agc,atten,val,freqs,unpacked_coeff)

fid = fopen(filename_in,'rb');

t_bin = 100e-3;   %time bin [s]
piece = floor(t_bin*freqs*2/unpacked_coeff);
fseek(fid,0,1);
nword = (ftell(fid));
fseek(fid,0,-1);

nl = floor(nword/piece);

nl = nl/unpacked_coeff;

tt = linspace(0,100,numel(agc));
agc_resampled = interp1(tt,agc,(0:nl-1)*t_bin);

P = zeros(nl,nf);

h = waitbar(0,['Gathering Spectrum Information...']);

for n = 0:nl-1
    npiece = min(piece,nword-n*piece);
    
    data = fread(fid, unpacked_coeff*npiece,'schar'); % read the data from the opened file - fid
    s = data(1:2:end) + 1i*data(2:2:end);
    
    s = s-mean(s); %remove DC
    [P(n+1,:),Freq] = pwelch(s, floor(npiece/8) , floor(npiece/16) , nf , freqs , 'twosided' );
    P(n+1,:) = fftshift(P(n+1,:));
    scale = atten(find(val>agc_resampled(n+1),1,'first'));
    if(isempty(scale))
        scale  = atten(end);
    end
    P(n+1,:) = 10^(-scale/10) * P(n+1,:);
    waitbar((n+1)/(nl),h);
end

fclose(fid);
close(h);
[F,T] = meshgrid(Freq-freqs/2,(0:nl-1)*t_bin);
end