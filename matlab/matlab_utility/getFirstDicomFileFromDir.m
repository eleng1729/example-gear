

% This helper gets the first file it can find in a directory that holds
% dicom files. Returns [] if it can't find a dicom file
function fname = getFirstDicomFileFromDir(dirname)

dir_struct = dirWithNoDotsNoDirs(dirname);
numfiles = size(dir_struct,2);
fname = [];
for idx=1:numfiles
    
    fname = fullfile(dirname, dir_struct(idx).name);
    if isdicom(fname)
        % Got it!
        return;
    end
    
end

