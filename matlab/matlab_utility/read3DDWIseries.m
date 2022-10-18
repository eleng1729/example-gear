%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function reads in a directory containing dicom files. It assumes
% there are multiple slices, bvalues, and acquisitions. Only 1 echo
% It does not make
% assumptions about the order they are written. Rather, it reads them all
% in, identifies the unique acquisition #s and slice positions, and reads them
% into a 4 dimensional matrix
%
% This is very much like readT2MultisliceDataset
%
%   sourcedir = a directory full of approrpiate dicom files
%   imageset5D = the resultant data, (rows, cols, Nslices, NBvalues, Nacq)
%   timevals = an array of the Timepoints, 1xNacq
%   firstTimepointInfos = array of 1xNacq dicominfos for AcquisitionNumber=1.
%
% 20130616 - Added support for multiple echoes. To avoid breaking other
% code, this just interleaves the echoes with the acquisitions. So if you
% have 2 echoes, the 4th dim is (acq 1 echo 1), (acq 1 echo 2), (acq2
% echo1), etc. FirstTimepointInfos are a little less clear in this case;
% you'll get numslices*numechoes.

% 20141027 - Copied from read3DTimeseries(), modified it to use b-values
% rather than time points
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [imageset5D, bvals, firstTimepointInfos] = read3DDWIseries(sourcedir)
imageset5D = [];


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
fprintf('Reading in file headers:    \n');
for idx=1:numfiles
    %fprintf('\b\b\b%3d', idx);
    info(idx) = dicominfo(fullfile(sourcedir, filelist(idx).name));
    sortinfo(idx, 1) = info(idx).InstanceNumber;
    if isfield(info(idx), 'AcquisitionNumber')
        sortinfo(idx, 2) = info(idx).AcquisitionNumber;
    else
        sortinfo(idx, 2) = 1;
    end
    
    % B-values are recorded in (0019, 100c). Vector is in 100e
    %sortinfo(idx, 3) = str2num(info(idx).AcquisitionTime);
    %     if isfield(info(idx), 'AcquisitionTime')
    %
    %         sortinfo(idx, 3) = dicomTimestampToSeconds(info(idx).AcquisitionTime);
    %     else
    %        sortinfo(idx, 3) = 0;
    %     end
    if isfield(info(idx), 'Private_0019_100c')
        
        sortinfo(idx, 3) = info(idx).Private_0019_100c;
    else
        sortinfo(idx, 3) = 0;
    end
    sortinfo(idx, 4) = info(idx).SliceLocation;
    sortinfo(idx, 5) = idx; % order that it was read in
    
    % Adding support for multiple echoes.
    sortinfo(idx, 6) = info(idx).EchoNumber;
    
    fprintf('Inst %d, EchoNum %d, bval %f,  SliceLoc %f\n', ...
        sortinfo(idx,1), sortinfo(idx,2), sortinfo(idx,3), sortinfo(idx,4));
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

% If it's a second acquisition in a series, min and max will both be 2
minacq = min(sortinfo(:,2));
maxacq = max(sortinfo(:,2));
numacqs = maxacq-minacq+1;

minecho = min(sortinfo(:,6));
maxecho = max(sortinfo(:,6));
numechoes = max(sortinfo(:,6));


% Get an ordered list of echo times
bvals = unique(sortinfo(:,3))';
fprintf('Found %d b-values from %.1f to %.1f ms\n', ...
    max(size(bvals)), min(bvals), max(bvals));
numbvals = max(size(bvals));

if numechoes>1
    error('This version does not support multiple echoes\n');
end
numslices = numfiles/(numacqs*numbvals);

cols = info(1).Width;
rows = info(1).Height;

% We also select those dicominfo structures from the first TE, and return
% these. They are later used to create new dicominfos for generated dicom
% files.

% PJB: if it is "save separate series" case, then this will not be 1
%firstTimepointIndices = sortinfo(:,2)==1;
firstTimepointIndices = sortinfo(:,2)==min(sortinfo(:,2));

firstTimepointInfos = info(firstTimepointIndices);
sortinfoFromFirstTimepoints = sortinfo(firstTimepointIndices,:);

% Figure out the slice positions. We do not res-ort these
slicepositions = sortinfo(firstTimepointIndices, 4);
fprintf('Found %d slices from %.1f to %.1f \n', ...
    numslices, min(slicepositions), max(slicepositions));

% Note: Now you can select from the set. For example, the indices for slice
% #5 can be found with: sortinfo(:,4)==slicepositions(5)

% This allocates a complex double array of the appropriate size
imageset5D = zeros(rows, cols, numslices, numbvals, numacqs);

% Record a few values to check that they do not vary over the series
try
    % Siemens parsing
    [img, ser, mrprot] = parse_siemens_shadow(firstTimepointInfos(1));
    bGainValid =  mrprot.sRXSPEC.bGainValid;
    if isfield(mrprot.sRXSPEC, 'lGain');
        lGain = mrprot.sRXSPEC.lGain;
    else
        lGain=-1;
    end
    flFirstFFTScaleFactor = mrprot.asCoilSelectMeas.aFFT_SCALE(1).flFactor;
    
    fprintf('gain %d/%d, firstScaleFactor %f\n', bGainValid, lGain, flFirstFFTScaleFactor);
catch
    fprintf('problem reading gain values \n');
end

% Iterate over all and read in.
fprintf('Reading in images:    \n');
acqechoidx = 0; % This is an interleaved acquisition/echo index.
for slidx=1:numslices
    
    % Select a subset of the sortinfo for this slice
    sortinfo_slice = sortinfo(sortinfo(:,4)==slicepositions(slidx),:);
    
    for bidx=1:numbvals
        
        % Pick out all that match this bval
        sortinfo_slice_bval = sortinfo_slice(sortinfo_slice(:,3)==bvals(bidx),:);
        
        for acqidx=(1:numacqs)
            
            sortinfo_slice_bval_acq = sortinfo_slice_bval( sortinfo_slice_bval(:,2)==acqidx, :);
            
            
            
            % FOR DWI, fixed this
            %fileReadIndex = sortinfo_slice(sortinfo_slice(:,6)==echonum, 5);
            fileReadIndex = sortinfo_slice_bval_acq(:,5);
            fname = info(fileReadIndex).Filename;
            fprintf('Slice %d, bVal# %d, Acq# %d, file=%s\n', slidx, bidx, acqidx, fname);
            img = dicomread(fname);
            imageset5D(:,:,slidx, bidx, acqidx) = img;
        end
        
    end
    fprintf('done.\n');
end

return;

