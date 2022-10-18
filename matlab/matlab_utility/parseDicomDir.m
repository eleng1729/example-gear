% This function lists all the files in a directory and lists some of the
% dicom tags. If a targetdir is provided, it will copy all those files to a
% new area using a human-readable hierarchical file format.
function parseDicomDir(dirname, targetdir)

dir_struct = dirWithNoDotsNoDirs(dirname);
numfiles = size(dir_struct,2);
fprintf('Found %d files:\n', numfiles);


% If there is a targetdir, it will copy the files to that directory and
% name them in a human-readable form
bCopy = false;
if nargin>1
    if exist(targetdir, 'dir')
        fprintf('Copying files to human-readable form in %s\n');
        bCopy = true;
    else
        error('targetdir %s does not exist.\n', targetdir);
    end
else
    fprintf('No target specified, just printing\n');
end


for idx=1:numfiles
    
    fname = fullfile(dirname, dir_struct(idx).name);
    
    if  ~isdicom(fname)
        fprintf('%d,%s, not-dicom\n', idx, dir_struct(idx).name);
    else
        hdr = dicominfo(fname);
        sequenceName = getFieldIfExists(hdr, 'SequenceName');
        seriesDescription = getFieldIfExists(hdr, 'SeriesDescription');
        
        if bCopy
            seriesdirname = sprintf('MR-SE%03d-%s', hdr.SeriesNumber, seriesDescription);
            seriesdirname = legalizeFilename(seriesdirname);
            
            if exist(fullfile(targetdir, seriesdirname), 'dir') == 0
                mkdir(targetdir, seriesdirname);
            end
            
            % If no acquisition number set it to 1
            if ~isfield(hdr, 'AcquisitionNumber')
                hdr.AcquisitionNumber = 1;
            end
            
            targetfname = fullfile(targetdir, seriesdirname, ...
                sprintf('acq%04d-inst%04d.dcm', hdr.AcquisitionNumber, hdr.InstanceNumber));
            fprintf('%s\n', targetfname);
            copyfile(fname, targetfname);
        else
            fprintf('%d <%s>, (%d,%d,%d), %s, sequence = ''%s''\n', idx, dir_struct(idx).name, ...
                hdr.SeriesNumber, hdr.AcquisitionNumber, hdr.InstanceNumber, ...
                seriesDescription, sequenceName);
        end
        
    end
end



function val = getFieldIfExists(hdr, fieldname);
if ~isfield(hdr, fieldname)
    val = '';
else
    val = getfield(hdr, fieldname);
end


function newfname = legalizeFilename(oldfname)
% these characters are allowed
legalchars = 'a-zA-Z0-9\-\_\.' ;

% illegal filename
%A = 'Some@characters$are(not&allowed.txt'

% replace every other character with an underscore
newfname = regexprep(oldfname,['[^' legalchars ']'],'_');
