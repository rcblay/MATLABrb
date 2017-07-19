function [F,T,P] = spectroRealTime(fid,agc,val,atten)

% Sets bin size for time and finds file size
unpacked_coeff = 4;
freqs = 16.3676e6/4;
nf = 1024;
t_bin = 100e-3;   %time bin [s]
piece = floor(t_bin*freqs*2/unpacked_coeff);

[data,nword] = fread(fid, 'schar'); 

% Calculates number of loops
nl = floor(nword/piece);
nl = floor(nl/unpacked_coeff);

% Creates array for time and obtains agc_resampled
tt = linspace(0,100,numel(agc));
agc_resampled = interp1(tt,agc,(0:nl-1)*t_bin);
% Pre-allocates for P
P = zeros(nl,nf);
% Begins waitbar
h = waitbar(0,['Gathering Spectrum Information...']);
% Loops through and calculates spectrum information

for n = 0:nl-1
    % Just here to catch remainder if piece does not divide nicely into the
    % size of the file
    npiece = min(piece,nword-n*piece);
    dataLoop = data((1 + n*unpacked_coeff*piece):(unpacked_coeff*npiece + n*unpacked_coeff*piece));
    % Condenses I and Q into single elements
    s = dataLoop(1:2:end) + 1i*dataLoop(2:2:end);
    % Remove DC (zero mean)
    s = s-mean(s); 
    % Call pwelch on data and do frequency analysis
    [P(n+1,:),Freq] = pwelch(s, floor(npiece/8) , floor(npiece/16) , nf , freqs , 'twosided' );
    P(n+1,:) = fftshift(P(n+1,:));
    scale = atten(find(val>agc_resampled(n+1),1,'first'));
    if(isempty(scale))
        scale  = atten(end);
    end
    P(n+1,:) = 10^(-scale/10) * P(n+1,:);
    % Update waitbar
    waitbar((n+1)/(nl),h);
end
% Close file and waitbar
close(h);
% Transform data into meshgrid coordinates
[F,T] = meshgrid(Freq-freqs/2,(0:nl-1)*t_bin);
end