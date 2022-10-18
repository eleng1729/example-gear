%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function reads in a directory containing dicom files. It assumes
% there are multiple slices and multiple timepoints. It does not make
% assumptions about the order they are written. Rather, it reads them all
% in, identifies the unique acquisition #s and slice positions, and reads them
% into a 4 dimensional matrix 
%
% This is very much like readT2MultisliceDataset
%
%   sourcedir = a directory full of approrpiate dicom files
%   imageset4D = the resultant data, (rows, cols, Nslices, Nacq)
%   timevals = an array of the Timepoints, 1xNacq
%   firstTimepointInfos = array of 1xNacq dicominfos for AcquisitionNumber=1. 

% The trick here is that the AFI sequences was kinda thrown together, and
% there is nothing in the header (I know of!?) that tells you which
% instances are #1 and #2. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [imageset4D, timevals, firstTimepointInfos, TR] = ...
    readDicom3DAFI(sourcedir)
imageset4D = [];

% Check to see that this is a valid directory
if (exist(sourcedir, 'dir') == 0)
    error('Cannot find directory %s', sourcedir);
end

% Get a list of files from this directory
filelist = dirWithNoDotsNoDirs(sourcedir);
numfiles = size(filelist,2);
fprintf('Found %d files\n', numfiles);

% Iterate over each and load the dicom info. Figure out how many echo times
% there are, how many slices there are.
% Fill in this little array: sortinfo(inst, echonum, echotime, sliceloc)
sortinfo = zeros(numfiles, 4);
fprintf('Reading in file headers:    ');
for idx=1:numfiles
    fprintf('\b\b\b%3d', idx);
    info(idx) = dicominfo(fullfile(sourcedir, filelist(idx).name));
    sortinfo(idx, 1) = info(idx).InstanceNumber;
    sortinfo(idx, 2) = info(idx).AcquisitionNumber;
    %sortinfo(idx, 3) = str2num(info(idx).AcquisitionTime);
    sortinfo(idx, 3) = dicomTimestampToSeconds(info(idx).AcquisitionTime);
    sortinfo(idx, 4) = info(idx).SliceLocation;
    sortinfo(idx, 5) = idx; % order that it was read in
    
    %disp(sprintf('Inst %d, EchoNum %d, TE %f,  SliceLoc %f', ...
    %    sortinfo(idx,1), sortinfo(idx,2), sortinfo(idx,3), sortinfo(idx,4)));
end
fprintf('\n');

% Typically the files are read in with the following order:
%   Inst    Acq     Slice
%   1       1       1
%   2       2       1
%   3       3       1
%   4       4       1
%   5       1       2
%   6       2       2
%   ...
% However, the logic below should work correctly for data that is written
% out in some other order, although it has not been tested. 

numacqs = max(sortinfo(:,2));

% AFI HACK
numacqs = 2;

numslices = numfiles/numacqs;

% Get an ordered list of echo times
timevals = unique(sortinfo(:,3))';
fprintf('Found %d Acq values from %.1f to %.1f ms\n', ...
    numacqs, min(timevals), max(timevals));

cols = info(1).Width;
rows = info(1).Height;

% We also select those dicominfo structures from the first TE, and return
% these. They are later used to create new dicominfos for generated dicom
% files. 
firstTimepointIndices = sortinfo(:,2)==1;
firstTimepointInfos = info(firstTimepointIndices);
sortinfoFromFirstTimepoints = sortinfo(firstTimepointIndices,:);

% Figure out the slice positions. We do not res-ort these
slicepositions = sortinfo(firstTimepointIndices, 4)
fprintf('Found %d slices from %.1f to %.1f \n', ...
    numslices, min(slicepositions), max(slicepositions));

% Note: Now you can select from the set. For example, the indices for slice
% #5 can be found with: sortinfo(:,4)==slicepositions(5)

% This allocates a complex double array of the appropriate size
imageset4D = zeros(rows, cols, numslices, numacqs);


% Have to look up the TR values by parsing the protocol
[img, ser, mrprot] = parse_siemens_shadow(firstTimepointInfos(1));
fprintf('Ref Voltage %.1fV\n', mrprot.sTXSPEC.asNucleusInfo(1).flReferenceAmplitude);
trBase = mrprot.alTR(1)
trOffset = mrprot.sWiPMemBlock.alFree(12)
TR(1)=trBase-trOffset;
TR(2)=trBase+trOffset;

% Iterate over all and read in. 
fprintf('Reading in images:    \n');
for slidx=1:numslices
    
    % Select a subset of the sortinfo for this slice
    sortinfo_slice = sortinfo(sortinfo(:,4)==slicepositions(slidx),:);
       
    % The sortinfo_slice structure has 2 rows,
    for acqidx=1:2
        fileReadIndex = sortinfo_slice(acqidx,5);
        
        fname = info(fileReadIndex).Filename;
        fprintf('Slice %d, TR# %d, file=%s\n', slidx, acqidx, fname);
        img = dicomread(fname);
        imageset4D(:,:,slidx, acqidx) = img;
    end
    
end
fprintf('done.\n');

return;

