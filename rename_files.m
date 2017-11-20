folder = '/mnt/admin/Brandon_Idaho/Night4/NT1065';

D = dir(folder);
nf = numel(D);

for i=3:nf
    file = D(i).name;
    newfile = ['Idaho_' file];
    movefile([folder '/' file],[folder '/' newfile]);
end