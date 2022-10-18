********************************************************************************
May 27, 1010 Patrick Bolan
This is standalone matlab code to generate a T2Map from a series of multiecho 
dicom data, and produces new DICOM data.
********************************************************************************
The code is run by first creating a configuration file, following the model of
input-template.xml. Copy this and modify as needed. Then 3 functions can be run 
using the same input file:

	fitT2Map(inputfile) - Creates the output structures and performs the fitting. 
	Can take a long time

	reviewT2Fit(inputfile) - Opens windows showing both the input and output data. 
	Clicking on the output brings up the T2 plot and fits.

	generateDicomFromT2Analysis(inputfile) - Creates the dicom requested in the 
	inputfile. Note that this is called automatically from fitT2Map.

The configuration reader is encapsulated in matlab object. You can use it like 
this:
	config = T2FitConfiguration(inputfile);
	disp(config.analysisPath);
	config.cleanOutput(); % This will delete all outputs! Careful!

This code works on 2 types of data so far: a 4D series containing multiple 2D 
slices and multiple echoes (like se_mc_ms); or a set of dicom series each with 
different effective TEs (like running 3 TSEs).

This code is parallelized, and runs much faster if you have the Matlab parallel 
compute toolbox. It will process each slice on different cores. To utilize this, 
configure a pool prior to running the fitting, using something like 
	"matlabpool local 7". 

Options are detailed in input-template.xml. Linear fitting is fast but biased, 
exp3 is preferred, but be sure to review the results for bias.

NOTE: Any substantive change requires a new version so as not to break shared 
code!
