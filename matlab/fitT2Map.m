function fitT2Map(config_file_path, output_dir)

if ~exist(config_file_path, 'file')
    error('%s does not exist!', (config_file_path));
else
    raw_config = jsondecode(fileread(config_file_path));
end

inputfile = raw_config.inputs.t2map_config.location.path;

% Specify version
verstring = '1.2';
verdate = '20100523';
verdescription = 'Repackaged and made independent of ovarian code';

% Create the configuration file reader
config = ProcessConfiguration(inputfile);
fprintf('outputRoot = %s\n', config.outputRoot)
fprintf('fileRoot = %s\n', config.fileRoot)
fprintf('analysisPath = %s\n', config.analysisPath)
fprintf('sourceScan = %s\n', config.sourceScans{1})

% Create the output root if it does not exist
if ~exist(config.outputRoot, 'dir')
    fprintf('Creating output root directory %s\n', config.outputRoot);
    mkdir(config.outputRoot);
end
if ~exist(config.analysisPath, 'dir')
    fprintf('Creating analysis  directory %s\n', config.analysisPath);
    mkdir(config.analysisPath);
end

% Start log and print basic info
logfile = [config.analysisPath filesep 'analysis_' verstring '_log_' datestr(now, 30) '.log'];
diary(logfile);
start_time = tic;

fprintf('Performing T2 mapping analysis\n');
fprintf('version = %s, date = %s\n', verstring, verdate);
fprintf('input file: %s\n', inputfile);
fprintf('output root: %s\n', config.outputRoot);

% Copy the inputfile to the output directory
copyOfInputFile = fullfile(config.analysisPath, 'inputFileCopy.xml');
fprintf('Copying the input file to %s\n', copyOfInputFile);
cmd = sprintf('cp %s %s', inputfile, copyOfInputFile);
system(cmd);

% Step 1: Read the source data into an inputdata structure and save
inputdatafile = fullfile(config.analysisPath, 'inputdata.mat');
numscans = size(config.sourceScans, 2);
if numscans == 1
    [~, sourcedir, ~] = fileparts(config.sourceScans{1});
    
    [imageset4D, tevals, firstTEinfos] = ...
        readT2MultisliceDataset(sourcedir);
    [rows, cols, numslices, numechoes] = ...
        size(imageset4D);
else
    % Assume each series is a volume with different TE. Assemble.
    for idx = 1:numscans
        sourcedir = config.sourceScans{idx};
        [imageset3D, te, teinfos] = ...
            readT2MultisliceDataset(sourcedir);
        [rows, cols, numslices, dummy] = ...
            size(imageset3D);
        
        if idx == 1
           % Initialize
           imageset4D = zeros(rows, cols, numslices, numscans);
           firstTEinfos = teinfos;
        end
        imageset4D(:, :, :, idx) = imageset3D;
        tevals(idx) = te;
    end
    numechoes = numscans;
end

inputdata.imageset4D = imageset4D;
inputdata.tevals = tevals;
inputdata.firstTEinfos = firstTEinfos;
inputdata.rows = rows;
inputdata.cols = cols;
inputdata.numslices = numslices;
inputdata.numechoes = numechoes;

% Save this file out
save(inputdatafile, 'inputdata');
clear inputdata

fprintf('Dataset read, rows %d, cols %d, slices %d, TEs %d\n',...
    rows, cols, numslices, numechoes);

% Step 2: trim the dataset
% Trim the first N echoes
numEchoesToTrim = str2num(config.getOption('discard-first-N-echoes'));

if numEchoesToTrim > 0
    imageset4D = imageset4D(:, :, :, (1+numEchoesToTrim):numechoes);
    tevals = tevals((1+numEchoesToTrim):numechoes);
    numechoes = numechoes - numEchoesToTrim;
    fprintf('Ignoring the first %d echoes\n', numEchoesToTrim);
end

% Prepare the output structures
T2map3d = zeros(rows, cols, numslices);
T2sdmap3d = zeros(rows, cols, numslices);
M0map3d = zeros(rows, cols, numslices);
M0sdmap3d = zeros(rows, cols, numslices);
Minfmap3d = zeros(rows, cols, numslices);
Minfsdmap3d = zeros(rows, cols, numslices);

% In order to use parfor, must remove the config object from loop
noisemaskmethod = config.getOption('noisemask/method');
noisemaskvalue = config.getOption('noisemask/value');
fittingmodel = config.getOption('fitting/model');

fittingtolX = str2num(config.getOption('fitting/TolX'));
fittingtolFun = str2num(config.getOption('fitting/TolFun'));

% Start parallel pool of workers
[~, nWorkers] = system('cat /proc/cpuinfo |grep "cpu cores" | awk -F: ''{ num+=$2 } END{ print num }''');
nWorkers = str2double(nWorkers);
maxNumCompThreads(nWorkers);

fprintf(['Number of cores available: ' num2str(nWorkers) '\n']);

poolObj = gcp('nocreate');

if isempty(poolObj)
    parpool;
    poolObj = gcp;
    
    if isempty(poolObj)
        nWorkers = 0;
    else
        nWorkers = poolObj.NumWorkers;
    end
else
    nWorkers = poolObj.NumWorkers;
end

fprintf(['Number of cores used: ' num2str(nWorkers) '\n']);

% Iterate over all slices
% for slidx=1:numslices
% numpools = 7; %matlabpool('size');
% if numpools==0
    % fprintf('Running on a single core.\n');
% else
    % fprintf('***********************************************************\n');
    % fprintf('** Running on %d parallel cores. Log files are asynchronous. \n', numpools);
    % fprintf('***********************************************************\n');
% end
parfor slidx=1:numslices

    % Extract this slice data
    imageset3D = squeeze(imageset4D(:,:,slidx,:));
    
    % Create the noise mask
    % There are two options specifiable in the config file.
    % Option 1 is to use Otsu's method (matlabs' graythresh), with a fudge
    % factor that can raise or lower the mask level. Defaults to Otsu,
    % fudge factor 1.
    % Option 2 is to use SNR with a specified noise level. This is
    % trickier, since noise is estimated from last image while
    
    switch noisemaskmethod;
        case {'otsu', ''}
            % Using Otsu's method as implemented in matlab's graythresh. This is
            % often too conservative, so user's can specify different
            % values
            signal_img = imageset3D(:,:,2);
            normimg = signal_img ./ max(signal_img(:)); % Normalize
            level = graythresh(normimg);
            
            fudge_factor = str2num(noisemaskvalue);
            if isempty(fudge_factor)
                fudge_factor = 1;
            end
            mask = im2bw(normimg, level * fudge_factor);
            fprintf('Masking with Otsu''s method, otsu level=%f, factor=%f, actual level=%f\n',...
                level, fudge_factor, level* fudge_factor * max(signal_img(:)) );
            
        case 'snr'
            % Now use the 2nd image for calculating treshholds (need at 
            % least 2 points for T2 fits):
            % PJB 2009113: use the last timepoint for noise estimation and the
            % third image for signal estimation. For larger
            % subjects the signal fills all the way out to the corners, making this
            % noise estimate too high.
            signal_img = imageset3D(:,:,2);                     
            
            %noise_img = imageset3D(:,:,numechoes);            
            %noiseregion = noise_img(5:20, 5:20);
            %imgnoise = std(noiseregion(:));
            
            % New noise metric based on temporal analysis
            imgnoise = estimate_noise_from_2D_timeseries(imageset3D);
            
            % Get the specified SNR threshold
            snr_threshold = str2num(noisemaskvalue);
            if isempty(snr_threshold)
                snr_threshold = 15;
            end            
            threshold = imgnoise*snr_threshold;
            
            % Create a mask
            mask = zeros(size(signal_img));
            mask(signal_img(:)<threshold) = 0;
            mask(signal_img(:)>=threshold) = 1;
            fprintf('Masking using SNR, snr_treshold=%f, actual level=%f\n',...
                snr_threshold, threshold);
            
        otherwise
            error('invalid nose mask method');
    end
        
    % Extra masking to go fast
    if (false)
        fastmask = mask .* 0;
        %fastmask(100:150, 100:150) = 1;
        fastmask(142:187, 127:201) = 1;
        %fastmask(169:172, 160:161) = 1;
        mask = mask .* fastmask;
        
        % Only do 1 slice
        if slidx ~=6
            mask = mask .* 0;
        end
    end
    
    
    fprintf('******************* Slice %d of %d\n', ...
        slidx, numslices);
    %[T2map, M0map, T2sdmap, M0sdmap, Minf, Minfsdmap] = ...
    %    fit2DT2(imageset3D, mask, tevals, config);
    [T2map, M0map, T2sdmap, M0sdmap, Minf, Minfsdmap] = ...
        fit2DT2(imageset3D, mask, tevals, ...
        fittingmodel, fittingtolX, fittingtolFun);
    
    % Rebuild a 4D dataset from each of the 3D solns
    T2map3d(:,:,slidx)      = T2map;
    T2sdmap3d(:,:,slidx)    = T2sdmap;
    M0map3d(:,:,slidx)      = M0map;
    M0sdmap3d(:,:,slidx)    = M0sdmap;    
    Minfmap3d(:,:,slidx)      = Minf;
    Minfsdmap3d(:,:,slidx)    = Minfsdmap;    
    
    fprintf('---> finished slice %d of %d\n', ...
        slidx, numslices);
end

t2fitting.T2map     = T2map3d;
t2fitting.T2sdmap    = T2sdmap3d;
t2fitting.M0map     = M0map3d;
t2fitting.M0sdmap    = M0sdmap3d;
t2fitting.Minfmap    = Minfmap3d;
t2fitting.Minfsdmap    = Minfsdmap3d;
t2fitting.version = version;
t2fitting.timestamp = datestr(now, 30);
t2fitting.model = config.getOption('fitting/model');

save(fullfile(config.analysisPath, 't2fitting.mat'), 't2fitting');


% Generate dicom
generateDicomFromT2Analysis(inputfile)

% Zip results and cleanup
zip('output.zip', config.outputRoot);
system('chmod -R 755 ./');
movefile('output.zip', fullfile(config.outputRoot, 'output.zip'));
rmdir(config.analysisPath, 's');
rmdir(config.generatedDicomPath, 's');

% End analysis
duration = toc(start_time);
fprintf('Completed in %0.1f minutes (%.0fs)\n', duration/60, duration);
diary off;
return;
