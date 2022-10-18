%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Produces clickable plots of the maps, and shows associated curves. Does
% not do the fitting. 
% Assumes a 2-parameter fit. 
% Works for a single slice. To do 3D or 2D multislice, call this function
% repeatedly. 
%
% Arguments:
%   imageset - a 3D array, with dimensions (Nx, Ny, Nte)
%   te_vals - an array of TEs, 1xNte. Units should be ms
%   T2map - a double-valued array (Nx, Ny) of T2 values, in ms units
%   T2sdmap - map of standard deviations of T2, same units
%   M0map - the fit M0 map.
%   M0sdmap - map of standard deviations of M0, same units
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hFig = review2DT2Fit(...
    imageset, te_vals, T2map, M0map, Minfmap, T2sdmap, M0sdmap, Minfsdmap, otheraxes) 

bShowMinf = 0;
if bShowMinf
   rows = 3; 
else
    rows = 2;
end

% Show the main plots
hFig = figure(121);
subplot(rows,2,1)
hImg = imagesc(T2map, [0 500]);
set(gca,'xtick',[],'ytick',[]);
axis equal; axis tight;
%colorbar
title('T2 map');
set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
set(hImg, 'Tag', 'T2map');
allaxes(1) = gca;

subplot(rows,2,2);
hImg = imagesc(T2sdmap./T2map * 100, [0 50]);
set(gca,'xtick',[],'ytick',[]);
axis equal; axis tight;
%colorbar
title('T2 stddev % map');
set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
set(hImg, 'Tag', 'T2stddevmap');
allaxes(2) = gca;

subplot(rows,2,3)
hImg = imagesc(M0map);
set(gca,'xtick',[],'ytick',[]);
axis equal; axis tight;
%colorbar
title('M0 map');
set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
set(hImg, 'Tag', 'M0map');
allaxes(3) = gca;

subplot(rows,2,4);
hImg = imagesc(M0sdmap ./ M0map * 100, [0 50]);
set(gca,'xtick',[],'ytick',[]);
axis equal; axis tight;
%colorbar
title('M0 stddev % map');
set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
set(hImg, 'Tag', 'M0stddevmap');
allaxes(4) = gca;

if bShowMinf
    subplot(rows,2,5)
    hImg = imagesc(Minfmap, [0 200]);
    set(gca,'xtick',[],'ytick',[]);
    axis equal; axis tight;
    %colorbar
    title('Minf map');
    set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
    allaxes(5) = gca;
    
    subplot(rows,2,6);
    hImg = imagesc(Minfsdmap ./ Minfmap * 100, [0 50]);
    set(gca,'xtick',[],'ytick',[]);
    axis equal; axis tight;
    %colorbar
    title('Minf stddev % map');
    set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
    allaxes(6) = gca;
end

% Put the pixel display on instead of a colorbar
impixelinfo

% Sync zooms
linkaxes([allaxes otheraxes], 'xy');

% Hang the current data on the figure so the callback can get it
setappdata(hFig, 'imageset', imageset);
setappdata(hFig, 'te_vals', te_vals);
setappdata(hFig, 'T2map', T2map);
setappdata(hFig, 'M0map', M0map);
setappdata(hFig, 'Minfmap', Minfmap);
setappdata(hFig, 'T2sdmap', T2sdmap);
setappdata(hFig, 'M0sdmap', M0sdmap);
setappdata(hFig, 'Minfsdmap', Minfsdmap);

setappdata(hFig, 'imageset', imageset);




