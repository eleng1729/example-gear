% This is a wrapper that calls Matlab's xmlwrite function to produce an xml
% file, but then re-writes it to remove all the extra newlines that Matlab
% likes to write
function xmlwritefile(filename, DOMnode);

% First just write it out as a temp filename
tempfile = tempname;
xmlwrite(tempfile, DOMnode);

fpin = fopen(tempfile, 'r');
fpout = fopen(filename, 'w');

% Now it's written. Read in and write back out line-by-line.
tline = fgetl(fpin);
while ischar(tline)
    cleanline = deblank(tline);
    if strcmp(cleanline, '')~=1      
        fprintf(fpout, '%s\n', cleanline);       
    end
    
    tline = fgetl(fpin);
end

fclose(fpin);
fclose(fpout);


% Finally, remove the temp file
delete(tempfile);
