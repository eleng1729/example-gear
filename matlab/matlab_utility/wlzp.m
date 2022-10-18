function wlzp(varargin)

% This function implements mouse interaction commonly used for DICOM
% images, specifically the default interaction provided by Osirix for a 2D
% single-slice image:
%   left mouse: adjust window/level
%   middle mouse: pan
%   right mouse: zoom
%   double-click: reset all

% This work was inspired by "enableWL" by Yi Sui:
% https://www.mathworks.com/matlabcentral/fileexchange/38491-adjust-window-level-of-image-using-mouse-button

% Patrick Bolan, University of Minnestoa
% May 30, 2017
figH = gcf;

% Option to uninstall the callbacks
if nargin>0
    if strcmpi(varargin(1), 'off')==1
        set(figH, 'WindowButtonDownFcn', '');
        set(figH, 'WindowButtonUpFcn', '');
        set(figH, 'WindowButtonMotionFcn', '');  
        return;
    end
end

% Save the old widow functions in app data
G.oldWBMFcn = get(figH, 'WindowButtonMotionFcn');
G.oldWBDFcn = get(figH, 'WindowButtonDownFcn');
G.oldWBUFcn = get(figH, 'WindowButtonUpFcn');

% Install our own button down and up functions, defined below
set(figH, 'WindowButtonDownFcn', @wlzpWBDFcn);
set(figH, 'WindowButtonUpFcn', @wlzpWBUFcn);

% Save the original values at the time it starts as "orig". These can then
% be reset with a double-click
G.origClim = get(gca, 'Clim');
G.origXlim = get(gca, 'Xlim');
G.origYlim = get(gca, 'Ylim');
setappdata(figH, 'wlzp_var', G);

return;


% Special Window Button down function
function wlzpWBDFcn(varargin)
figH = varargin{1};
G = getappdata(figH,'wlzp_var');

% Need to store original values in my data
G.initpnt = get(gca,'currentpoint');
G.initClim = get(gca,'Clim');
G.initXlim = get(gca,'Xlim');
G.initYlim = get(gca,'Ylim');
setappdata(figH, 'wlzp_var', G);

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
        set(gca, 'Clim', G.origClim);
        set(gca, 'Xlim', G.origXlim);
        set(gca, 'Ylim', G.origYlim);
end

return;


% Special Window Button Up function
% Restore the previously installed motion callback
function wlzpWBUFcn(varargin)
figH = varargin{1};
G = getappdata(figH,'wlzp_var');
set(figH,'WindowButtonMotionFcn', G.oldWBMFcn);


% Interactive adjustment of window/level
function AdjWL(varargin)
figH = varargin{1};
G = getappdata(figH, 'wlzp_var');
cp = get(gca,'currentpoint');
dx = cp(1,1) - G.initpnt(1,1);
dy = cp(1,2) - G.initpnt(1,2);

% My estimation of Osirix's behavior
window = G.initClim(2)-G.initClim(1);
level = mean(G.initClim(:));

% Change them
scaleW = .05;
scaleL = 1;
level = level + dy .* scaleL;
window = window .* (1/(1+dx * scaleW));

% Recalc clim
G.clim(1) = level-window/2;
G.clim(2) = level+window/2;

% Some error checks on the clim
if G.clim(2) <= G.clim(1)
    G.clim(2) = G.clim(1)*1.000000001;
end

% Set these values and return
set(gca, 'Clim', G.clim);
return;



% Interactive adjustment of window/level
function AdjZoom(varargin)
figH = varargin{1};
G = getappdata(figH, 'wlzp_var');
cp = get(gca,'currentpoint');
dx = cp(1,1) - G.initpnt(1,1);
dy = cp(1,2) - G.initpnt(1,2);

% need to maintain aspect ratio
dataAspectRatio = get(gca, 'dataaspectratio');
yratio = dataAspectRatio(2)/dataAspectRatio(1);

scaleZoom = .5;
xlim(1) = G.initXlim(1) - dy * scaleZoom;
xlim(2) = G.initXlim(2) + dy * scaleZoom;
ylim(1) = G.initYlim(1) - dy * scaleZoom * yratio;
ylim(2) = G.initYlim(2) + dy * scaleZoom * yratio;

% Set these values and return
set(gca, 'Xlim', xlim);
set(gca, 'Ylim', ylim);
return;


% Interactive adjustment of window/level
function AdjPan(varargin)
figH = varargin{1};
G = getappdata(figH, 'wlzp_var');
cp = get(gca,'currentpoint');
dx = cp(1,1) - G.initpnt(1,1);
dy = cp(1,2) - G.initpnt(1,2);

% Pan by changing the limits
set(gca, 'Xlim', G.initXlim - dx);
set(gca, 'Ylim', G.initYlim - dy);

% For Pan, we have to re-initialize the point because the units are based
% on the current axes, which have just changed.
G.initpnt = get(gca, 'currentpoint');
G.initXlim = get(gca, 'Xlim');
G.initYlim = get(gca, 'Ylim');
setappdata(figH, 'wlzp_var', G);

return;



