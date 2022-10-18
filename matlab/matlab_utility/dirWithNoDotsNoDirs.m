function dir_struct = dirWithNoDotsNoDirs(fullpath)
dir_struct_orig = dir(fullpath);

% Fixed a bug in this. If the dir was empty, it would return '..'

% First, lets pull out '.' and '..'
idx = 1;
dir_struct = [];

for idx = 1:size(dir_struct_orig,1);
    if (strcmp(dir_struct_orig(idx).name, '.'))
        0;

    elseif (strcmp(dir_struct_orig(idx).name, '..'))
        0;
        
    elseif (strcmp(dir_struct_orig(idx).name, '.DS_Store'))
        % Ignore stupid mac hacks
        0;
        
    elseif dir_struct_orig(idx).isdir
        0;
        
    else
        % Append to the output dir
        dir_struct = [dir_struct dir_struct_orig(idx)];
    end
end
