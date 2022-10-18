% This loads and reviews the T2 fitting data specified in the config file
function reviewT2Fit(inputfile)

% Create the configuration file reader
config = ProcessConfiguration(inputfile);

% Expecting two files: inputdata.mat and t2fitting.mat
inputdatafile = fullfile(config.analysisPath, 'inputdata.mat');
load(inputdatafile);

t2FittingFilename = fullfile(config.analysisPath, 't2fitting.mat');
load(t2FittingFilename);

% Make these available in the workspace too
assignin('base', 'inputdata', inputdata);
assignin('base', 't2fitting', t2fitting);

reviewT2FitGui(inputdata.imageset4D, inputdata.tevals, t2fitting);



