% This converts the T2 output to DICOM.
% Pass a directory containing inputdata.mat and t2fitting.mat
%function generateDicomFromT2Analysis(studydir, t2FittingFilename)
function generateDicomFromT2Analysis(inputfile)

% Create the configuration file reader
config = ProcessConfiguration(inputfile);

% Load up fitting and inputdata
inputdataFilename = fullfile(config.analysisPath, 'inputdata.mat');
t2FittingFilename = fullfile(config.analysisPath, 't2fitting.mat');
load(inputdataFilename);
load(t2FittingFilename);

% Set target directory
targetdir = config.generatedDicomPath;
if(exist(targetdir) == 0)
    fprintf('Making dicom output directory %s\n', targetdir);
    mkdir(targetdir);
end

% First, T2 maps
if strcmpi(config.getOption('generate-T2-dicom'), 'true')==1
    
    fprintf('\nGenerating T2 maps\n');
    % New series info
    newSeriesUID = dicomuid();
    newSeriesNum = inputdata.firstTEinfos(1).SeriesNumber + 101; 
    %newSeriesName = 'T2_map';
    newSeriesName = sprintf('T2_map_%s', config.getOption('fitting/model'));
    
    % Make a directory for the individual files
    newSeriesDirname = sprintf('MR-SE%03d-%s', newSeriesNum, newSeriesName);
    seriesdir = fullfile(targetdir, newSeriesDirname);
    if(exist(seriesdir) == 0)
        fprintf('Making series directory %s\n', seriesdir);
        mkdir(seriesdir);
    end
    
    for idx=1:inputdata.numslices
        % Start with the info structure from echo #1 for this slice
        output_info = inputdata.firstTEinfos(1);
        
        % Modify the info
        output_info.SOPInstanceUID=dicomuid();
        output_info.InstanceCreationDate = datestr(now, 'yyyymmdd');
        output_info.ImageType = 'DERIVED\SECONDARY\M\DIS2D';
        output_info.EchoTime = mean(inputdata.tevals);
        output_info.NumberOfAverages = inputdata.numechoes;
        output_info.EchoNumber = 1;
        output_info.SeriesDescription = newSeriesName;
        output_info.SeriesInstanceUID = newSeriesUID;
        output_info.SeriesNumber = newSeriesNum;
        output_info.InstanceNumber = idx;

       
     
        fname = sprintf('MR-SE%03d-%04d.dcm', newSeriesNum, idx);
        filename = fullfile(seriesdir, fname);
        
        t2map = squeeze(t2fitting.T2map(:,:,idx));

        % Rescaling.
        % For T2 there is no need to rescale, but we'll clean up values out
        % of range
        t2map(t2map<0) = 0;
        t2map(t2map>4095) = 4095;
        output_info.RescaleSlope = 1;
        output_info.RescaleIntercept = 0;
        output_info.WindowCenter = 200;
        output_info.WindowWidth = 400;
        
        fprintf('Writing file %s\n', filename);
        % Adding the CreateMode turns off Matlabs error checking, which
        % removes the Rescale info
        dicomwrite(uint16(t2map), filename, output_info, 'CreateMode', 'Copy');
        
    end   
end

% Then M0 maps
if strcmpi(config.getOption('generate-M0-dicom'), 'true')==1
    
    fprintf('Generating M0 maps');
    
    % New series info
    newSeriesUID = dicomuid();
    newSeriesNum = inputdata.firstTEinfos(1).SeriesNumber + 102;
    %newSeriesName = 'M0_map';   
    newSeriesName = sprintf('M0_map_%s', config.getOption('fitting/model'));
    
    % Make a directory for the individual files
    newSeriesDirname = sprintf('MR-SE%03d-%s', newSeriesNum, newSeriesName);
    seriesdir = fullfile(targetdir, newSeriesDirname);
    if(exist(seriesdir) == 0)
        fprintf('Making series directory %s\n', seriesdir);
        mkdir(seriesdir);
    end
    
    for idx=1:inputdata.numslices
        % Start with the info structure from echo #1 for this slice
        output_info = inputdata.firstTEinfos(1);
        
        % Modify the info
        output_info.SOPInstanceUID=dicomuid();
        output_info.InstanceCreationDate = datestr(now, 'yyyymmdd');
        output_info.ImageType = 'DERIVED\SECONDARY\M\DIS2D';
        output_info.EchoTime = mean(inputdata.tevals);
        output_info.NumberOfAverages = inputdata.numechoes;
        output_info.EchoNumber = 1;
        output_info.SeriesDescription = newSeriesName;
        output_info.SeriesInstanceUID = newSeriesUID;
        output_info.SeriesNumber = newSeriesNum;
        output_info.InstanceNumber = idx;
        
        fname = sprintf('MR-SE%03d-%04d.dcm', newSeriesNum, idx);
        filename = fullfile(seriesdir, fname);
        
        img = squeeze(t2fitting.M0map(:,:,idx));
        
        % Rescaling.
        % For M0 there is no need to rescale, but we'll clean up values out
        % of range
        img(img<0) = 0;
        img(img>4095) = 4095;
        output_info.RescaleSlope = 1;
        output_info.RescaleIntercept = 0;
        %output_info.WindowCenter = 200; % No specified windowing
        %output_info.WindowWidth = 400;
        
        fprintf('Writing file %s\n', filename);
        dicomwrite(uint16(img), filename, output_info);
        
    end   
end

disp('Dicom generation completed.');

