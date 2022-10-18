%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function reads in a directory containing dicom files. It assumes
% there are multiple slices and multiple TE values. It does not make
% assumptions about the order they are written. Rather, it reads them all
% in, identifies the unique echo times and slices positions, and reads them
% into a 4 dimensional matrix 
%
%   sourcedir = a directory full of approrpiate dicom files
%   imageset4D = the resultant data, (rows, cols, Nslices, Nte)
%   tevals = an array of the echo times, 1xNte
%   firstTEinfos = array of Nte dicominfos for EchoNumber=1. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [imageset4D, tevals, firstTEinfos] = readT2MultisliceDataset(sourcedir)
imageset4D = [];

% Check to see that this is a valid directory
if (exist(sourcedir, 'dir') == 0)
    error('Cannot find directory %s', sourcedir);
end

% Get a list of files from this directory
filelist = dirWithNoDotsNoDirs(sourcedir);
numfiles = size(filelist,2);
fprintf('Found %d files\n', numfiles);

% First iterate over and find all the dicom infos.
% This may fail sometimes; that's fine, we'll just proceed, and the rest of
% the code will read all images that have a readable info
fprintf('Reading in %d file headers, in parallel...', numfiles);
infos = cell(numfiles,1);
for idx=1:numfiles
    %fprintf('\b\b\b%3d', idx);
    fname = fullfile(sourcedir, filelist(idx).name);
    if ~isdicom(fname)
        fprintf('%d: ignoring non-dicom file %s \n', idx, fname);
    else
        %fprintf('%d: %s\n', idx, fname);
        
        % Note these have to be cells because the fields may not all be
        % identical (as is the case with MB)
        infos{idx} = dicominfo(fname);
    end
end
fprintf(' completed.\n');

% Remove the non-dicom files
infos = infos(~cellfun('isempty', infos));
numfiles = size(infos,1);


% Iterate over each and load the dicom info. Figure out how many echo times
% there are, how many slices there are.
% Fill in this little array: sortinfo(inst, echonum, echotime, sliceloc)
sortinfo = zeros(numfiles, 4);
fprintf('Reading in file headers:    ');
for idx=1:numfiles
    fprintf('\b\b\b%3d', idx);
    %info(idx) = dicominfo(fullfile(sourcedir, filelist(idx).name));
    sortinfo(idx, 1) = infos{idx}.InstanceNumber;
    sortinfo(idx, 2) = infos{idx}.EchoNumbers;
    sortinfo(idx, 3) = infos{idx}.EchoTime;
    sortinfo(idx, 4) = infos{idx}.SliceLocation;
    sortinfo(idx, 5) = idx; % order that it was read in
    
    %disp(sprintf('Inst %d, EchoNum %d, TE %f,  SliceLoc %f', ...
    %    sortinfo(idx,1), sortinfo(idx,2), sortinfo(idx,3), sortinfo(idx,4)));
end
fprintf('\n');

% Typically the files are read in with the following order:
%   Inst    Echo    Slice
%   1       1       1
%   2       2       1
%   3       3       1
%   4       4       1
%   5       1       2
%   6       2       2
%   ...
% However, the logic below should work correctly for data that is written
% out in some other order, although it has not been tested. 

numechoes = max(sortinfo(:,2));
numslices = numfiles/numechoes;

% Get an ordered list of echo times
tevals = unique(sortinfo(:,3))';
fprintf('Found %d TE values from %.1f to %.1f ms\n', ...
    numechoes, min(tevals), max(tevals));

cols = infos{1}.Width;
rows = infos{1}.Height;

% We also select those dicominfo structures from the first TE, and return
% these. They are later used to create new dicominfos for generated dicom
% files. 
firstTEindices = sortinfo(:,2)==1;
firstTEinfos = infos{firstTEindices};
sortinfoFromFirstTEs = sortinfo(firstTEindices,:);

% Figure out the slice positions. We do not res-ort these
slicepositions = sortinfo(firstTEindices, 4);
fprintf('Found %d slices from %.1f to %.1f \n', ...
    numslices, min(slicepositions), max(slicepositions));

% Note: Now you can select from the set. For example, the indices for slice
% #5 can be found with: sortinfo(:,4)==slicepositions(5)

% This allocates a complex double array of the appropriate size
imageset4D = zeros(rows, cols, numslices, numechoes);

% Iterate over all and read in. 
fprintf('Reading in images:    \n');
for slidx=1:numslices
    
    % Select a subset of the sortinfo for this slice
    sortinfo_slice = sortinfo(sortinfo(:,4)==slicepositions(slidx),:);
    
    for teidx=1:numechoes
        
        fileReadIndex = sortinfo_slice(sortinfo_slice(:,2)==teidx, 5);
        fname = infos{fileReadIndex}.Filename;
        fprintf('Slice %d, TE %d, file=%s\n', slidx, teidx, fname);     
        img = dicomread(fname);
        imageset4D(:,:,slidx, teidx) = img;

    end
end
fprintf('done.\n');

return;

