function filename = findFile(fullpath)
% This looks for a filename, potentially with wildcards
% If there is 1 match, it is returned
% If there are multiple matches, null is returned
% if there are no matches, null is returned

if exist(fullpath) == 2 
	filename = fullpath;
	return;
end;

dir_struct = dirWithNoDotsNoDirs(fullpath);

filename = [];
if(size(dir_struct, 2) > 1) 
	disp(sprintf('Found %d matches for to %s', ...
		size(dir_struct, 2), fullpath ));
elseif(size(dir_struct, 2) < 1)
	disp(sprintf('Found 0 matches for to %s', fullpath ));
else
	filename = [fileparts(fullpath) filesep dir_struct.name];
end

return;
