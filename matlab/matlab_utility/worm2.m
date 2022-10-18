% Worm 2 is my work in process 4D viewer. No plotting, but 4 display

function worm2(img3d)

figH = figure();
[Nx, Ny, Nz, Nt] = size(img3d);

fprintf('Data has dimensions (%d, %d, %d, %d)\n', Nx, Ny, Nz, Nt);
if isunix()
    fprintf('\tLeft mouse:       W/L\n');
    fprintf('\tShift Left mouse: Pan\n');
    fprintf('\tCtrl Left mouse:  Zoom\n');
    fprintf('\tMouse wheel:      slice\n');
    fprintf('\tUp/down keys:     time\n');
else
    fprintf('\tLeft mouse:       W/L\n');
    fprintf('\tMiddle mouse:     Pan\n');
    fprintf('\tRight mouse:      Zoom\n');
    fprintf('\tMouse wheel:      slice\n');
    fprintf('\tUp/down keys:     time\n');    
end
    
    
% Save the timepoints
apd.timept = 1;
apd.NtimePts = Nt;

sl = round(Nz/2);
imgH = imagesc(img3d(:,:,sl));
apd.imgH = imgH;

% Save the image and slice number as appdata
apd.slice = sl;
apd.Nslices = Nz;
apd.img3d = img3d;
title(sprintf('slice %d/%d time %d/%d\n', apd.slice, apd.Nslices, apd.timept, apd.NtimePts));

% Install our own button down and up functions, defined below
set(figH, 'WindowButtonDownFcn', @wormWBDFcn);
set(figH, 'WindowButtonUpFcn', @wormWBUFcn);
set(figH, 'WindowScrollWheelFcn', @wormWSWFcn);
set(figH, 'KeyPressFcn', @wormKPFcn);


% Save the original values at the time it starts as "orig". These can then
% be reset with a double-click
apd.origClim = get(gca, 'Clim');
apd.origXlim = get(gca, 'Xlim');
apd.origYlim = get(gca, 'Ylim');
setappdata(figH, 'worm_var', apd);
impixelinfo

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
        
    otherwise
        newTimept = apd.timept;
end

% Check range
newTimept = max(1,newTimept);
newTimept = min(apd.NtimePts, newTimept);
apd.timept = newTimept;
set(apd.imgH, 'CData', apd.img3d(:,:,apd.slice, apd.timept));
setappdata(figH, 'worm_var', apd);
title(sprintf('slice %d/%d time %d/%d\n', apd.slice, apd.Nslices, apd.timept, apd.NtimePts));

return


% Window scrolling function
function wormWSWFcn(varargin)
figH = varargin{1};
scrollStruct = varargin{2};
apd = getappdata(figH, 'worm_var');

sliceCur = apd.slice;
sliceNew = sliceCur + scrollStruct.VerticalScrollCount;

% Check the sliceNew bounds
sliceNew = max(1, sliceNew);
sliceNew = min(apd.Nslices, sliceNew);

% Change slice
apd.slice = sliceNew;
title(sprintf('slice %d/%d time %d/%d\n', apd.slice, apd.Nslices, apd.timept, apd.NtimePts));
set(apd.imgH, 'CData', apd.img3d(:,:,sliceNew, apd.timept));
setappdata(figH, 'worm_var', apd);

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
        % Reset
        set(gca, 'Clim', apd.origClim);
        set(gca, 'Xlim', apd.origXlim);
        set(gca, 'Ylim', apd.origYlim);
        % Don't reset the slices
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
scaleW = .005;
scaleL = 1;
level = level + dy .* scaleL;
window = window .* (1/(1+dx * scaleW));

% Recalc clim
apd.clim(1) = level-window/2;
apd.clim(2) = level+window/2;

% Some error checks on the clim
if apd.clim(2) <= apd.clim(1)
    apd.clim(2) = apd.clim(1)*1.000000001;
end

% Set these values and return
set(gca, 'Clim', apd.clim);
return;



% Interactive adjustment of window/level
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


% Interactive adjustment of window/level
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



