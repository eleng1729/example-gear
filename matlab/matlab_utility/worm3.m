
% Worm3 is my work in process 4D viewer. No plotting, but 4 display

function worm3(img3d)
fprintf('Worm3 v2\n');

if ~isreal(img3d)
    fprintf('*** NOTE: Input is complex; taking absolute value.\n');
    img3d = abs(img3d);
end


figH = figure();
colormap gray
[Nx, Ny, Nz, Nt] = size(img3d);

fprintf('Data has dimensions (%d, %d, %d, %d)\n', Nx, Ny, Nz, Nt);
if isunix()
    fprintf('\tLeft mouse:       W/L\n');
    fprintf('\tShift Left mouse: Pan\n');
    fprintf('\tCtrl Left mouse:  Zoom\n');
    fprintf('\tMouse wheel:      slice\n');
    fprintf('\tUp/down keys:     time\n');
    fprintf('\tDouble L-click:   center slices\n');  
    fprintf('\t''R'' key:        reset zoom & contrast\n');
    
else
    fprintf('\tLeft mouse:       W/L\n');
    fprintf('\tMiddle mouse:     Pan\n');
    fprintf('\tRight mouse:      Zoom\n');
    fprintf('\tMouse wheel:      slice\n');
    fprintf('\tUp/down keys:     time\n');    
    fprintf('\tDouble L-click:   center slices\n');  
    fprintf('\t''R'' key:        reset zoom & contrast\n');
end
lineColor = 'r';        

% Save the timepoints
apd.timept = 1;
apd.NtimePts = Nt;

slx = round(Nx/2);
sly = round(Ny/2);
slz = round(Nz/2);

% Setup the initial windows
% The Z-axis shows the XY plane (z is normal)
subplot(2,2,1)
imgHz = imagesc(squeeze(img3d(:,:,slz,1)));
apd.axisZ = gca;
apd.clim = get(gca, 'clim');
set(apd.axisZ, 'clim', apd.clim);

% Line notation: lineXZ is the x-slice line in the z-axes image
apd.lineXZ = line([1 Ny], [slx, slx], 'Color', lineColor);
apd.lineYZ = line([sly, sly], [1 Nx], 'Color', lineColor);

% Y axis
subplot(2,2,4)
imgHy = imagesc(rot90(squeeze(img3d(:,sly,:,1))), apd.clim);
apd.axisY = gca;
set(apd.axisY, 'clim', apd.clim);

apd.lineZY = line([1 Nx], [slz, slz], 'Color', lineColor);
apd.lineXY = line([slx, slx], [1 Nz], 'Color', lineColor);

% Xaxis
subplot(2,2,3)
imgHx = imagesc(rot90(squeeze(img3d(slx,:,:,1))), apd.clim);
apd.axisX = gca;
set(apd.axisX, 'clim', apd.clim);

apd.lineZX = line([1 Ny], [slz, slz], 'Color', lineColor);
apd.lineYX = line([sly, sly], [1 Nz], 'Color', lineColor);

% Plot. Just a place holder for now
subplot(2,2,2)
apd.axisPlot = gca;
plot(squeeze(img3d(Nx,Ny,Nz,:)));
set(apd.axisPlot, 'xlim', [0.5, apd.NtimePts+.5]);

apd.imgHx = imgHx;
apd.imgHy = imgHy;
apd.imgHz = imgHz;

% Note the range of values
apd.min = min(img3d(:));
apd.max = max(img3d(:));
apd.range = double(apd.max - apd.min);

% Save the image and slice number as appdata
apd.slice(1) = slx;
apd.slice(2) = sly;
apd.slice(3) = slz;
apd.N(1) = Nx;
apd.N(2) = Ny;
apd.N(3) = Nz;

apd.img3d = img3d;

% Install our own button down and up functions, defined below
set(figH, 'WindowButtonDownFcn', @wormWBDFcn);
set(figH, 'WindowButtonUpFcn', @wormWBUFcn);
set(figH, 'WindowScrollWheelFcn', @wormWSWFcn);
set(figH, 'KeyPressFcn', @wormKPFcn);


% Save the original values at the time it starts as "orig". These can then
% be reset with a double-click
apd.origClim = get(apd.axisZ, 'Clim');
apd.origXlimZ = get(apd.axisZ, 'Xlim');
apd.origYlimZ = get(apd.axisZ, 'Ylim');

apd.origXlimY = get(apd.axisY, 'Xlim');
apd.origYlimY = get(apd.axisY, 'Ylim');

apd.origXlimX = get(apd.axisX, 'Xlim');
apd.origYlimX = get(apd.axisX, 'Ylim');

setappdata(figH, 'worm_var', apd);

updateAll(figH);

set(figH, 'CurrentAxes', apd.axisZ);
impixelinfo

return;


% Update the images and text
function updateAll(figH)
apd = getappdata(figH, 'worm_var');

% Note the current axis
currentAxis = gca;

figure(figH)

% Check slice bounds
for sdx=1:3
    apd.slice(sdx) = max(0, apd.slice(sdx));
    apd.slice(sdx) = min(apd.N(sdx), apd.slice(sdx));
end

set(gcf, 'name', sprintf('Worm3 time %d/%d',  apd.timept, apd.NtimePts));

set(apd.imgHz, 'CData', squeeze(apd.img3d(:,:,apd.slice(3), apd.timept)));
set(apd.imgHy, 'CData', rot90(squeeze(apd.img3d(:,apd.slice(2),:, apd.timept))));
set(apd.imgHx, 'CData', rot90(squeeze(apd.img3d(apd.slice(1),:,:, apd.timept))));

% Draw slices
set(apd.lineXZ, 'ydata', [1 1].*apd.slice(1) );
set(apd.lineYZ, 'xdata', [1 1].*apd.slice(2) );

% PJB 
%set(apd.lineZY, 'ydata', apd.N(3) - 1 - ([1 1].*apd.slice(3)) );
set(apd.lineZY, 'ydata', apd.N(3) + 1 - ([1 1].*apd.slice(3)) );
set(apd.lineXY, 'xdata', [1 1].*apd.slice(1) );

set(apd.lineZX, 'ydata', apd.N(3) + 1 - ([1 1].*apd.slice(3)) );
set(apd.lineYX, 'xdata', [1 1].*apd.slice(2) );

% Update plot
set(figH, 'CurrentAxes', apd.axisPlot);
plot(squeeze(apd.img3d(apd.slice(1),apd.slice(2),apd.slice(3),:)));
set(apd.axisPlot, 'xlim', [0.5, apd.NtimePts+.5]);
set(apd.axisPlot, 'ylim', apd.clim);
xlabel('Fourth dimension')
title(sprintf('[%d, %d, %d]', apd.slice(1),apd.slice(2),apd.slice(3)));

set(figH, 'CurrentAxes', currentAxis);

return;


% Keypress function
function wormKPFcn(varargin)
figH = varargin{1};
kpStruct = varargin{2};
apd = getappdata(figH, 'worm_var');

% uparrow, downarrow
switch kpStruct.Key
    case 'uparrow'
        newTimept = apd.timept + 1;
        
    case 'downarrow'
        newTimept = apd.timept - 1;
        
    case {'r', 'R'}
        % Reset
        set(apd.axisZ, 'Clim', apd.origClim);
        set(apd.axisY, 'Clim', apd.origClim);
        set(apd.axisX, 'Clim', apd.origClim);
        
        set(apd.axisZ, 'Xlim', apd.origXlimZ);
        set(apd.axisZ, 'Ylim', apd.origYlimZ);
        
        set(apd.axisY, 'Xlim', apd.origXlimY);
        set(apd.axisY, 'Ylim', apd.origYlimY);
        
        set(apd.axisX, 'Xlim', apd.origXlimX);
        set(apd.axisX, 'Ylim', apd.origYlimX);
        newTimept = apd.timept;
        
    otherwise
        newTimept = apd.timept;
end

% Check range
newTimept = max(1,newTimept);
newTimept = min(apd.NtimePts, newTimept);
apd.timept = newTimept;

setappdata(figH, 'worm_var', apd);
updateAll(figH);

return


% Window scrolling function
function wormWSWFcn(varargin)
figH = varargin{1};
scrollStruct = varargin{2};
apd = getappdata(figH, 'worm_var');

% Figure out which direction to scroll
if gca==apd.axisZ
    axnum = 3;
elseif gca==apd.axisY
    axnum = 2;
else
    axnum = 1;
end

sliceCur = apd.slice(axnum);
sliceNew = sliceCur + scrollStruct.VerticalScrollCount;

% Check the sliceNew bounds
sliceNew = max(1, sliceNew);
sliceNew = min(apd.N(axnum), sliceNew);

% Change slice
apd.slice(axnum) = sliceNew;
%title(sprintf('slice %d/%d time %d/%d\n', apd.slice, apd.Nslices, apd.timept, apd.NtimePts));
%set(apd.imgH, 'CData', apd.img3d(:,:,sliceNew, apd.timept));
setappdata(figH, 'worm_var', apd);
updateAll(figH);
return;


% Special Window Button down function
function wormWBDFcn(varargin)
figH = varargin{1};
apd = getappdata(figH,'worm_var');

% Need to store original values in my data
apd.initpnt = get(gca,'currentpoint');
apd.initClim = get(gca,'Clim');
apd.initXlim = get(gca,'Xlim');
apd.initYlim = get(gca,'Ylim');
setappdata(figH, 'worm_var', apd);

% Actions depend on mouse button clicked
switch get(figH, 'SelectionType')
    
    case 'normal' % Left click
        set(figH, 'WindowButtonMotionFcn', @AdjWL);
        
    case 'alt' % Right Click
        set(figH, 'WindowButtonMotionFcn', @AdjZoom);
        
    case 'extend' % click middle (mouse wheel)
        set(figH, 'WindowButtonMotionFcn', @AdjPan);
        
    case 'open' % double-click
        % Center slices
        cp = get(gca,'currentpoint');
        if (gca == apd.axisZ)
            apd.slice(2) = round(cp(1,1));
            apd.slice(1) = round(cp(1,2));
            
        elseif (gca == apd.axisY)
            apd.slice(1) = round(cp(1,1));
            apd.slice(3) = apd.N(3)-1-round(cp(1,2));
            
        elseif(gca == apd.axisX)
            apd.slice(2) = round(cp(1,1));
            apd.slice(3) = apd.N(3)-1-round(cp(1,2));
        end
        
        % Set the slices
        setappdata(figH, 'worm_var', apd);
        updateAll(figH);
 
end

return;


% Special Window Button Up function
% Restore the previously installed motion callback
function wormWBUFcn(varargin)
figH = varargin{1};
apd = getappdata(figH,'worm_var');
set(figH,'WindowButtonMotionFcn', []);
impixelinfo
return


% Interactive adjustment of window/level
function AdjWL(varargin)
figH = varargin{1};
apd = getappdata(figH, 'worm_var');
cp = get(gca,'currentpoint');
dx = cp(1,1) - apd.initpnt(1,1);
dy = cp(1,2) - apd.initpnt(1,2);

% My estimation of Osirix's behavior
window = apd.initClim(2)-apd.initClim(1);
level = mean(apd.initClim(:));

% Change them
scaleW = .0001 * apd.range;
scaleL = 0.002 * apd.range;
level = level + dy .* scaleL;
level = max(level, 0);
window = window .* (1/(1+dx * scaleW));

fprintf('window %f\n', window);
% Recalc clim
apd.clim(1) = level-window/2;
apd.clim(2) = level+window/2;

% Some error checks on the clim
if apd.clim(2) <= apd.clim(1)
    apd.clim(2) = apd.clim(1)*1.000000001;
end

% Set these values and return
set(apd.axisZ, 'Clim', apd.clim);
set(apd.axisY, 'Clim', apd.clim);
set(apd.axisX, 'Clim', apd.clim);
setappdata(figH, 'worm_var', apd);

% Update the plot
updateAll(figH);
return;



% Interactive adjustment of zoom
function AdjZoom(varargin)
figH = varargin{1};
apd = getappdata(figH, 'worm_var');
cp = get(gca,'currentpoint');
dx = cp(1,1) - apd.initpnt(1,1);
dy = cp(1,2) - apd.initpnt(1,2);

% need to maintain aspect ratio
dataAspectRatio = get(gca, 'dataaspectratio');
yratio = dataAspectRatio(2)/dataAspectRatio(1);

scaleZoom = .5;
xlim(1) = apd.initXlim(1) - dy * scaleZoom;
xlim(2) = apd.initXlim(2) + dy * scaleZoom;
ylim(1) = apd.initYlim(1) - dy * scaleZoom * yratio;
ylim(2) = apd.initYlim(2) + dy * scaleZoom * yratio;

% Set these values and return
set(gca, 'Xlim', xlim);
set(gca, 'Ylim', ylim);
return;


% Interactive adjustment of Pan
function AdjPan(varargin)
figH = varargin{1};
apd = getappdata(figH, 'worm_var');
cp = get(gca,'currentpoint');
dx = cp(1,1) - apd.initpnt(1,1);
dy = cp(1,2) - apd.initpnt(1,2);

% Pan by changing the limits
set(gca, 'Xlim', apd.initXlim - dx);
set(gca, 'Ylim', apd.initYlim - dy);

% For Pan, we have to re-initialize the point because the units are based
% on the current axes, which have just changed.
apd.initpnt = get(gca, 'currentpoint');
apd.initXlim = get(gca, 'Xlim');
apd.initYlim = get(gca, 'Ylim');
setappdata(figH, 'worm_var', apd);

return;



