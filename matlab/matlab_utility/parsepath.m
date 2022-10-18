function strlist = parsepath(fullpath)

[tok, remain] = strtok(fullpath, filesep);
strlist = [];
while ~isempty(tok)
    strlist = strvcat(strlist, tok);   
    
    [tok, remain] = strtok(remain, filesep);
end