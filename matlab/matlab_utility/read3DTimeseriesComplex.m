%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is designed to read DICOM magnitude/phase pairs, and is
% built on top of read3DTimeseries.
%
% This is very much like readT2MultisliceDataset
%
%   sourcedir_mag = a directory full of the magnitude dicom files
%   sourcedir_phs = a directory full of the matching phase dicom files
%   imageset4D = the resultant complex data, (rows, cols, Nslices, Nacq)
%   timevals = an array of the Timepoints, 1xNacq
%   firstTimepointInfos = array of 1xNacq dicominfos for AcquisitionNumber=1. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [imageset4D, timevals, firstTimepointInfos] = read3DTimeseriesComplex(sourcedir_mag, sourcedir_phs)

[img_m, timevals, firstTimepointInfos] = read3DTimeseries(sourcedir_mag);

[img_p, ~, infos_p] = read3DTimeseries(sourcedir_phs);

% Note infos_p(1).RescaleType = 'US', which means unspecified. Nice. 
slope = infos_p(1).RescaleSlope;
intercept = infos_p(1).RescaleIntercept;
img_p = img_p .*slope + intercept;

% After rescaling, the scale should go from [-4096, 4096]. Rescale to
% radians
img_pr = img_p .* pi/4096;

% Reconstitue the complex data
imageset4D = img_m .* exp(1j.*img_pr);


return;

