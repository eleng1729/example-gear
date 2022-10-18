% 20150208
% For reasons I don't know, the previous version of this function won't
% work on PRISMA MB DWI dat, and I need it. Don't have time now to fix,
% jsut getting somethign working. 
%
% The DICOM info structure is not consistent across all slices in a MB
% series!

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
%
% 20130616 - Added support for multiple echoes. To avoid breaking other
% code, this just interleaves the echoes with the acquisitions. So if you
% have 2 echoes, the 4th dim is (acq 1 echo 1), (acq 1 echo 2), (acq2
% echo1), etc. FirstTimepointInfos are a little less clear in this case;
% you'll get numslices*numechoes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [imageset4D, timevals, firstTimepointInfos] = read3DTimeseries_MBVERSION(sourcedir)
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
fprintf('Reading in %d file headers:    ', numfiles);
for idx=1:numfiles
    fprintf('\b\b\b%3d', idx);   
    
    info_tmp = dicominfo(fullfile(sourcedir, filelist(idx).name));

    
    sortinfo(idx, 1) = info_tmp.InstanceNumber;
    if isfield(info_tmp, 'AcquisitionNumber')
        sortinfo(idx, 2) = info_tmp.AcquisitionNumber;
    else
        sortinfo(idx, 2) = 1;
    end
    %sortinfo(idx, 3) = str2num(info(idx).AcquisitionTime);
    if isfield(info_tmp, 'AcquisitionTime')
    
        sortinfo(idx, 3) = dicomTimestampToSeconds(info_tmp.AcquisitionTime);
    else
       sortinfo(idx, 3) = 0; 
    end
    sortinfo(idx, 4) = info_tmp.SliceLocation;
    sortinfo(idx, 5) = idx; % order that it was read in
    
    % Adding support for multiple echoes.
    sortinfo(idx, 6) = info_tmp.EchoNumber;
    
    %disp(sprintf('Inst %d, EchoNum %d, TE %f,  SliceLoc %f', ...
    %    sortinfo(idx,1), sortinfo(idx,2), sortinfo(idx,3), sortinfo(idx,4)));
    
    % HACK! Just save the first one out
    if idx==1
        info(idx) = info_tmp;
    end
    
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

numslices = numfiles/(numacqs*numechoes);

% Get an ordered list of echo times
timevals = unique(sortinfo(:,3))';
fprintf('Found %d Acq values from %.1f to %.1f ms\n', ...
    numacqs, min(timevals), max(timevals));

if numechoes>1
   fprintf('Found %d echos. These will be interleaved with acquisitions\n', numechoes);
end

cols = info(1).Width;
rows = info(1).Height;

% We also select those dicominfo structures from the first TE, and return
% these. They are later used to create new dicominfos for generated dicom
% files. 

% PJB: if it is "save separate series" case, then this will not be 1
%firstTimepointIndices = sortinfo(:,2)==1;
firstTimepointIndices = sortinfo(:,2)==min(sortinfo(:,2));

%firstTimepointInfos = info(firstTimepointIndices);
firstTimepointInfos = info(1); %HACK
sortinfoFromFirstTimepoints = sortinfo(firstTimepointIndices,:);

% Figure out the slice positions. We do not res-ort these
slicepositions = sortinfo(firstTimepointIndices, 4)
fprintf('Found %d slices from %.1f to %.1f \n', ...
    numslices, min(slicepositions), max(slicepositions));

% Note: Now you can select from the set. For example, the indices for slice
% #5 can be found with: sortinfo(:,4)==slicepositions(5)

% This allocates a complex double array of the appropriate size
imageset4D = zeros(rows, cols, numslices, numacqs*numechoes);


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
    
    for acqidx=(1:numacqs)
        
        % Select a further subset for this acquisition
        acqnum = acqidx-1+minacq;
        sortinfo_slice_acq = sortinfo_slice( sortinfo_slice(:,2)==acqnum, :);
        
        for echoidx=(1:numechoes)
                        
            % Pick out the 1 for this echo
            echonum = echoidx-1+minecho;
            acqechoidx = (acqnum-1)*numechoes + echonum;

            fileReadIndex = sortinfo_slice(sortinfo_slice(:,6)==echonum, 5);
            fname = info(fileReadIndex).Filename;
            fprintf('Slice %d, Acq# %d, Echo# %d, file=%s\n', slidx, acqnum, echonum, fname);
            img = dicomread(fname);
            imageset4D(:,:,slidx, acqechoidx) = img;
        end
    end
end
fprintf('done.\n');

return;

