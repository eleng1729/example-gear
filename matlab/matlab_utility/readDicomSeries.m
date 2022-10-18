% 20150311
% This is a more general version of read3DTimeseries, etc.
% Handles slice position, echoes, acquisitions, b-values.

% OK, here's a problem. For Product DWI with 3-scan trace, if you have 2
% bvalues, you get 1 acquisition. For DWI with a table, you get 1 acq for
% each entry, regardless if the b-values are the same.

% So the final index will be EITHER bvalue or acquisition!

% 201602 I had some problems with reading in Philips data in the proper
% order because they use SliceLocation differently. Now the slices are
% sorted from low to high values, in the direction most perpindicular to
% the image plane. For Sag the order is right-left, axial foot-head,
% coronal A-P

function [imgsort, infosort, images, infos] = readDicomSeries(sourcedir)
images = [];

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

% Read the images in. All images must be the same dimension
tmp = dicomread(infos{1});
[nRow, nCol] = size(tmp);
images = zeros(nRow, nCol, numfiles);
parfor idx=1:numfiles
    images(:,:,idx) = dicomread(infos{idx});
end

% The following will sort the images and infos. HOwever, for some homemade
% DICOM this can fail.
imgsort = [];
infosort = [];
try
    
    % Find the most perpendicular dimension
    orient = infos{1}.ImageOrientationPatient;
    normal = cross(orient(1:3), orient(4:6));
    [~, perpDir] = max(abs(normal));
    
    % Load up potentially sortable data fieds
    slicepos = zeros(numfiles,1);
    acqnum = ones(numfiles,1);
    acqtime = zeros(numfiles,1);
    echonum = zeros(numfiles,1);
    bvals = zeros(numfiles,1);
    for idx=1:numfiles
        
        % Slice position
        % The SlicePosition field is not reliable for Philips, as they use this
        % for the absolute distance from isocenter (+3 and -3 are identical!)
        %     if isfield(infos{idx}, 'SliceLocation');
        %         slicepos(idx) = infos{idx}.SliceLocation;
        %     else
        %         % Here I'm just guessing which one is correct
        %         slicepos(idx) = infos{idx}.ImagePositionPatient(1);
        %     end
        slicepos(idx) = infos{idx}.ImagePositionPatient(perpDir);
        
        % Acquisition number
        if isfield(infos{idx}, 'AcquisitionNumber');
            acqnum(idx) = infos{idx}.AcquisitionNumber;
        end
        
        % Acquisition time
        if isfield(infos{idx}, 'AcquisitionTime');
            if ~isempty(infos{idx}.AcquisitionTime)
                acqtime(idx) = dicomTimestampToSeconds(infos{idx}.AcquisitionTime);
            else
                acqtim(idx) = 0;
            end
        end
        
        % Echonumber
        if isfield(infos{idx}, 'EchoNumber');
            echonum(idx) = infos{idx}.EchoNumber;
        else
            echonum(idx) = 1;
        end
        
        % b-values
        if isfield(infos{idx}, 'Private_0019_100c')
            % THis can be more than 1
            bvals(idx) = mean(infos{idx}.Private_0019_100c);
        end
        
        %fprintf('%d/%d, loc=%.2f, acq=%d, time=%d, echo=%d\n', idx, numfiles, slicepos(idx), acqnum(idx), acqtime(idx), echonum(idx));
        
    end
    
    uslices = unique(slicepos);
    nSlices = size(uslices,1);
    uechoes = unique(echonum);
    nEchoes = size(uechoes,1);
    uacqs = unique(acqnum);
    nAcqs = size(uacqs,1);
    ubvals = unique(bvals);
    nBVals = size(ubvals,1);
    fprintf('Sorting into %d slices, %d echoes, %d bvals, %d acquisitions.\n', ...
        nSlices, nEchoes, nBVals, nAcqs);
    
    % Should have better logic here - see which approach makes sense in regards
    % to the total number, and sort the data accordingly
    if (nAcqs>nBVals)
        fprintf('Table mode; ordering by acquisition\n');
        
        % Now sort
        imgsort = zeros(nRow, nCol, nSlices, nEchoes, nAcqs);
        infosort = cell(nSlices,nEchoes,nAcqs);
        for idx=1:numfiles
            % Find indices
            slidx = uslices==slicepos(idx);
            echoidx = uechoes==echonum(idx);
            acqidx = uacqs==acqnum(idx);
            bidx = ubvals==bvals(idx);
            imgsort(:,:,slidx,echoidx,acqidx) = images(:,:,idx);
            infosort{slidx,echoidx,acqidx} = infos{idx};
        end
        
        
    else
        fprintf('Product Mode: ordering by b-values\n');
        
        imgsort = zeros(nRow, nCol, nSlices, nEchoes, nBVals);
        infosort = cell(nSlices,nEchoes,nAcqs);
        for idx=1:numfiles
            % Find indices
            slidx = uslices==slicepos(idx);
            echoidx = uechoes==echonum(idx);
            acqidx = uacqs==acqnum(idx);
            bidx = ubvals==bvals(idx);
            imgsort(:,:,slidx,echoidx,bidx) = images(:,:,idx);
            infosort{slidx,echoidx,bidx} = infos{idx};
        end
        
    end
catch
    warning('Malformed DICOM: could not sort.');
end

% May want to sort the uslices first, otherwise relying on file order



% Further enhancements may try to extract data from Siemens shadows, like
% this:

% try
%     % Siemens parsing
%     [img, ser, mrprot] = parse_siemens_shadow(firstTimepointInfos(1));
%     bGainValid =  mrprot.sRXSPEC.bGainValid;
%     if isfield(mrprot.sRXSPEC, 'lGain');
%         lGain = mrprot.sRXSPEC.lGain;
%     else
%         lGain=-1;
%     end
%     flFirstFFTScaleFactor = mrprot.asCoilSelectMeas.aFFT_SCALE(1).flFactor;
%
%     fprintf('gain %d/%d, firstScaleFactor %f\n', bGainValid, lGain, flFirstFFTScaleFactor);
% catch
%     fprintf('problem reading gain values \n');
% end



