% This function a directory that (presumably) contains DICOM series. It
% then looks at the metadata and figures out the study timing, and prints
% it out.
% Note this assumes that the files are already structured, with a directory
% for each series and files inside. You can create this structure using the
% function parseDicomDir.

function extractDicomSeriesTiming(studydir)

dir_struct = dirWithNoDotsNoFiles(studydir);
numseries = size(dir_struct,2);

starttime = 1E8;

for idx=1:numseries
    
    fname = fullfile(studydir, dir_struct(idx).name);
    
    % Get a test file and its header
    testfile = getFirstDicomFileFromDir(fname);
    hdr = dicominfo(testfile);
    
    % The "start" time is the AcquisitionTime (0008,0032)
    startTimeInSeconds = dicomTimestampToSeconds(hdr.AcquisitionTime);
    
    seriesDescription = getFieldIfExists(hdr, 'SeriesDescription');
    
    %fprintf('%d <%s>, %s, %s, %d\n', ...
    %    idx, dir_struct(idx).name, ...
    %    seriesDescription, hdr. AcquisitionTime, secs);
    
    seriesstruct(idx).name = seriesDescription;
    secs(idx) = startTimeInSeconds;
    
    if startTimeInSeconds<starttime
        starttime = startTimeInSeconds;
    end
end

% Now starttime is the earliest value

% Sort list
[~, newidx] = sort(secs);

% Loop again, print formatted:

fprintf('\nBy start times, in minutes\n');
fprintf('Start\tName\n');
for idx=1:size(seriesstruct,2)
    
    sIdx = newidx(idx); %
    fprintf('%.2f\t%s\n', (secs(sIdx) - starttime)/60, seriesstruct(sIdx).name);
end



% Helper to pull metadata from dicom file
function val = getFieldIfExists(hdr, fieldname);
if ~isfield(hdr, fieldname)
    val = '';
else
    val = getfield(hdr, fieldname);
end
