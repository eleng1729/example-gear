% When this gets called, it looks up the current point on the axes, and
% plots the T2 data
function view4DPlotCallback(hFig);

% Find the point clicked
cp = get(gca, 'CurrentPoint');
row = round(cp(1,2));
col = round(cp(1,1));
disp(sprintf('You clicked (x,y) = (%d, %d)', col, row));
%fprintf('The controllerfigure is %f\n', hFig);

% Pull the important data off the figure
imageset = getappdata(hFig, 'imageset');
xvals = getappdata(hFig, 'xvals');

% Get the current slice
slider_obj = findobj(hFig, 'Tag', 'sliderSlice');
curslice = get(slider_obj, 'Value');

% Extract data for this point
datavals = squeeze(imageset(row, col, curslice, :));

% Plot
plotfig = figure(122);
movegui(plotfig, 'northeast');


% First hte data
plot(xvals, datavals, '-o');
ylabel('Signal');

% Pin bottom to zero
ylim = get(gca, 'ylim')
set(gca, 'ylim', [0, max(ylim(:))]);



