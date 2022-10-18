function dir_struct = dirImageFilesOnly(fullpath)
dir_struct_orig = dir(fullpath);

% Fixed a bug in this. If the dir was empty, it would return '..'

% First, lets pull out '.' and '..'
idx = 1;
dir_struct = [];

for idx = 1:size(dir_struct_orig,1);
    
    filename = dir_struct_orig(idx).name;
    if (strcmp(filename, '.'))
        0;
        
    elseif (strcmp(filename, '..'))
        0;
        
    elseif dir_struct_orig(idx).isdir
        0;
        
    else
        %[PATHSTR,NAME,EXT,VERSN] = fileparts(filename);
        [PATHSTR,NAME,EXT] = fileparts(filename);
        
        % Switches not functioning correctly here:
        if ((strcmpi(EXT, '.png') == 1) || ...
                (strcmpi(EXT, '.jpg') == 1) || ...
                (strcmpi(EXT, '.tiff') == 1) )
            
            % Ignore the backup files starting with ._
            if (strcmpi(filename(1:2),'._') ~= 1)
                dir_struct = [dir_struct dir_struct_orig(idx)];
            end
            
        end
        
        % Append to the output dir
        
    end
end
