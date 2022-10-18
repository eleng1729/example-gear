
% This is a general function to generate the DICOM

% NOte that dicominfos should be a cell

function generateDicomSeries(seriesName, seriesNum, targetdir, dicominfo, img3D, ...
    RescaleSlope, RescaleIntercept, WindowCenter, WindowWidth)

% New series info
newSeriesUID = dicomuid();

% Make a directory for the individual files
newSeriesDirname = sprintf('MR-SE%03d-%s', seriesNum, seriesName);
seriesdir = fullfile(targetdir, newSeriesDirname);
if(exist(seriesdir) == 0)
    fprintf('Making series directory %s\n', seriesdir);
    mkdir(seriesdir);
end

[nRow, nCol, nSlc, nTE] = size(img3D);
parfor sdx=1:nSlc
    % Start with the info structure from echo #1 for this slice
    output_info = dicominfo{sdx};
    
    % Modify/Overwrite the info
    output_info.SOPInstanceUID=dicomuid();
    output_info.InstanceCreationDate = datestr(now, 'yyyymmdd');
    output_info.ImageType = 'DERIVED\SECONDARY\M\DIS2D';
    output_info.EchoNumber = 1;
    output_info.SeriesDescription = seriesName;
    output_info.SeriesInstanceUID = newSeriesUID;
    output_info.SeriesNumber = seriesNum;
    output_info.InstanceNumber = sdx;
    
    fname = sprintf('MR-SE%03d-%04d.dcm', seriesNum, sdx);
    filename = fullfile(seriesdir, fname);
    
    img = squeeze(img3D(:,:,sdx));
    
    if ~isempty(RescaleSlope)
        output_info.RescaleSlope = RescaleSlope;
    end
    if ~isempty(RescaleIntercept)
        output_info.RescaleIntercept = RescaleIntercept;
    end
    output_info.WindowCenter = WindowCenter;
    output_info.WindowWidth = WindowWidth;
    
    fprintf('Writing file %s\n', filename);
    % Adding the CreateMode turns off Matlabs error checkisng, which
    % removes the Rescale info
    tmp = uint16(round(img));
    
    
    warning off;
    % Note dicomwrite() is slow, maybe because of the warnings
    dicomwrite(tmp, filename, output_info, 'CreateMode', 'Copy');
    warning on;
    
end