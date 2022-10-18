function noiselevel = estimate_noise_from_2D_timeseries(imageset)

% Imageset should be (rows, columns, timepoint)
[rows, cols, pts] = size(imageset);

% Create an image of the temporal standard deviation
stdimg = std(imageset, 0, 3);

% Assume noise pixels are those that vary the least over time. 
% Find the smallest N pixels in the stdimag
sorted_vals = sort(stdimg(stdimg>0));

% Use the median of the smallest 5% of these values
numvals = size(sorted_vals,1);
noiselevel = median(sorted_vals(1:round(numvals.*0.05)));

% This is interesting to look at!
%figure(120)
%plot(sorted_vals);

% And re-make a figure showing these "noise" pixels
%indices = stdimg<noiselevel;
%figure(121)
%imagesc(indices);

