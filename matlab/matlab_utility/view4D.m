function varargout = view4D(varargin)
% VIEW4D M-file for view4D.fig
%      VIEW4D, by itself, creates a new VIEW4D or raises the existing
%      singleton*.
%
%      H = VIEW4D returns the handle to a new VIEW4D or the handle to
%      the existing singleton*.
%
%      VIEW4D('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEW4D.M with the given input arguments.
%
%      VIEW4D('Property','Value',...) creates a new VIEW4D or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before view4D_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to view4D_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help view4D

% Last Modified by GUIDE v2.5 17-Oct-2010 10:51:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @view4D_OpeningFcn, ...
                   'gui_OutputFcn',  @view4D_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before view4D is made visible.
function view4D_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to view4D (see VARARGIN)

% Choose default command line output for view4D
handles.output = hObject;
handles.figurehandle = hObject;
fprintf('The controllerfigure is %f\n', handles.figureView4D);

% Update handles structure
guidata(hObject, handles);

% Set some defaults
setappdata(handles.figurehandle, 'plotfigurehandle', 106)
if isempty(varargin)
    % Error! Need to pass in a spectrum
    disp('usage: view4d(imageset, label_4d), where imageset is (row, col, slice, 4thD)');
    error('incorrect usage - pass in a 4D matrix');
else
    
    % Inspect the imageset and store it
    imageset = varargin{1};
    [rows, cols, slices, series] = size(imageset);
    fprintf('imageset rows=%d, cols=%d, slices=%d, series=%d\n', ...
        rows, cols, slices, series);
    setappdata(handles.figurehandle, 'imageset', imageset);
    setappdata(handles.figurehandle, 'slices', slices);
    setappdata(handles.figurehandle, 'series', series);
    
    % Starting values
    curslice = round(slices/2);
    curseries = 1;
    
    % Setup the sliders
    set(handles.sliderSlice, 'Min', 1);
    set(handles.sliderSlice, 'Max', slices);
    set(handles.sliderSlice, 'Value', curslice);
    set(handles.sliderSlice, 'SliderStep', [1 4] .* (1/(slices-1)));    
    
    if (series>1)
        set(handles.sliderSeries, 'Min', 1);
        set(handles.sliderSeries, 'Max', series);
        set(handles.sliderSeries, 'Value', curseries);
        set(handles.sliderSeries, 'SliderStep', [1 4] .* (1/(series-1)));
    else
        disp('Reverting to 3D');
        set(handles.sliderSeries, 'Visible', 'off');
    end
        
    % Calculate the clip
    
    maxval = max(imageset(:));
    minval = min(imageset(:));
    highclip = round(maxval * 0.9);
    if (highclip<=minval) 
        highclip = minval + 1;
    end
    clipstr = sprintf('[%.3f %.3f]', minval, highclip);
    %clipstr = '[0 1000]';
    set(handles.editClip, 'String', clipstr);
    
    % Update
    guidata(hObject, handles);
    
    % Go ahead and plot
    displayImage(handles);
    
    % Change the 4thD label if passed in
    xvals = 1:series;
    if(size(varargin, 2) > 1)
        if ischar(varargin{2})
            set(handles.textFourthDimLabel, 'String', varargin{2});
        else
           % Assume this is actually axis values. Hopefuilly right siez
           xvals = varargin{2};
        end
    end
    
    setappdata(handles.figurehandle, 'xvals', xvals);
     
    
    
end






% --- Outputs from this function are returned to the command line.
function varargout = view4D_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% Main function that displays the image
function displayImage(handles)
imageset = getappdata(handles.figurehandle, 'imageset');
plot_fighandle = getappdata(handles.figurehandle, 'plotfigurehandle');

if (ishandle(plot_fighandle))
    figure(plot_fighandle);
else
    figure(plot_fighandle);
    movegui('northwest');
end

% Get the current slice and series information
curslice = get(handles.sliderSlice, 'Value');
curseries = get(handles.sliderSeries, 'Value');

slices = getappdata(handles.figurehandle, 'slices');
series = getappdata(handles.figurehandle, 'series');

% Get the clip information
clipstr = get(handles.editClip, 'String');
clip = str2num(clipstr);
if (series > 1)
    hImg = imagesc(squeeze(imageset(:,:,curslice,curseries)), clip);
else
    hImg = imagesc(squeeze(imageset(:,:,curslice)), clip);
end
setappdata(handles.figurehandle, 'imagehandle', hImg)
impixelinfo

set(gca,'xtick',[],'ytick',[]);
axis equal; axis tight;
%colorbar

%set(hImg, 'ButtonDownFcn', sprintf('callbackT2plot(%f)', hFig));
%set(hImg, 'ButtonDownFcn', 'disp(''hello!'')');
set(hImg, 'ButtonDownFcn', sprintf('view4DPlotCallback(%f)', handles.figureView4D));
%set(hImg, 'ButtonDownFcn', sprintf('view4D(''view4D_Plot4thD'', hObject, eventdata, handles)'));


% Update labels
set(handles.textSliceInfo, 'String', sprintf('%d/%d', curslice, slices));
set(handles.textSeriesInfo, 'String', sprintf('%d/%d', curseries, series));




% --- Executes on slider movement.
function sliderSlice_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA);

% Make sure it stays an integer
set(handles.sliderSlice, 'Value', ...
    round(get(handles.sliderSlice, 'Value')));
displayImage(handles);


% --- Executes during object creation, after setting all properties.
function sliderSlice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSeries_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSeries (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Make sure it stays an integer
set(handles.sliderSeries, 'Value', ...
    round(get(handles.sliderSeries, 'Value')));
displayImage(handles)


% --- Executes during object creation, after setting all properties.
function sliderSeries_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSeries (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




function editClip_Callback(hObject, eventdata, handles)
% hObject    handle to editClip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
displayImage(handles)


% --- Executes during object creation, after setting all properties.
function editClip_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function figureView4D_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figureView4D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
movegui('east')


% --- Executes on button press in pushbuttonClose.
function pushbuttonClose_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figureView4D);  % Delete this


% --- Executes during object deletion, before destroying properties.
function figureView4D_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figureView4D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plot_fighandle = getappdata(handles.figurehandle, 'plotfigurehandle');

if (ishandle(plot_fighandle))
    close(plot_fighandle);
end
delete(handles.figureView4D);  % Delete this


function view4D_Plot4thD(hObject, eventdata, handles)
disp('plotting 4th dimension');
imageset = getappdata(handles.figurehandle, 'imageset');
size(imageset)


% --- Executes on button press in pushbuttonROI.
function pushbuttonROI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get the current slice and series information
imageset = getappdata(handles.figurehandle, 'imageset');

curslice = get(handles.sliderSlice, 'Value');
curseries = get(handles.sliderSeries, 'Value');


% Get the clip information
clipstr = get(handles.editClip, 'String');
clip = str2num(clipstr);
if (series > 1)
    img2d = squeeze(imageset(:,:,curslice,curseries));
else
    img2d = squeeze(imageset(:,:,curslice));
end

roitool(img2d, clip, pwd);
gc

% --- Executes on button press in pushbuttonDrawROI.
function pushbuttonDrawROI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDrawROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Disable the callback
hImg = getappdata(handles.figurehandle, 'imagehandle');
set(hImg, 'ButtonDownFcn', '');

plot_fighandle = getappdata(handles.figurehandle, 'plotfigurehandle');
plot_axeshandle = get(plot_fighandle, 'CurrentAxes');

fprintf('Make a poly:\n');
hpoly = impoly(plot_axeshandle);

% Save the poly in the figure
setappdata(handles.figurehandle, 'roihandle', hpoly)

% Re-enable the plot callback
set(hImg, 'ButtonDownFcn', sprintf('view4DPlotCallback(%f)', handles.figureView4D));

% Call the update callback
pushbuttonUpdateROI_Callback(hObject, eventdata, handles)


% --- Executes on button press in pushbuttonUpdateROI.
function pushbuttonUpdateROI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUpdateROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hpoly = getappdata(handles.figurehandle, 'roihandle');
hImg = getappdata(handles.figurehandle, 'imagehandle');

BW = createMask(hpoly, hImg);
img = getimage(hImg);

vals = img(BW>0);

% Remove zero values
zvals = vals(vals==0);
vals = sort(vals(vals>0));

% Plot
figure(2) 
%hist(vals(vals>0), 100);
hist(vals(vals>0), 200);
set(gca, 'xlim', [0 max(vals(:))]);


% Calc distribution values
numvals = size(vals,1);
half = floor(numvals .* 0.5);
bot10 = floor(numvals .* 0.10);
bot25 = floor(numvals .* 0.25);
top10 = floor(numvals .* 0.90);
top25 = floor(numvals .* 0.75);


% Annotation Positioning
xlim = get(gca, 'xlim');
ylim = get(gca, 'ylim');
widthX = xlim(2) - xlim(1);
widthY = ylim(2) - ylim(1);

% Put my text Upper left or upper right
if mean(vals)>(xlim(1)+widthX/2)
    % plot UL
    textposX = xlim(1) + widthX * 0.03;
else
    % Plot UR
    textposX = xlim(2) - widthX * 0.2;    
end
textposY = ylim(2) - widthY * 0.25;


% Note! Matlab's Kurtosis function gives "3" for a normal distribution. The
% more common convention is to subtract 3
kurt = kurtosis(vals) - 3;

% Prep text strings
textstr{1} =    sprintf('#pix   %d', numvals);
textstr{2} =    sprintf('#zeros %d', max(size(zvals)) );
textstr{3} =    sprintf('mean   %.2f', mean(vals));
textstr{4} =    sprintf('median %.2f', median(vals));
textstr{5} =    sprintf('stdev  %.2f', std(vals));
textstr{6} =    sprintf('min    %.2f', min(vals));
textstr{7} =    sprintf('max    %.2f', max(vals));
textstr{8} =    sprintf('10%%    %.2f', vals(bot10));
textstr{9} =    sprintf('25%%    %.2f', vals(bot25));
textstr{10} =    sprintf('75%%    %.2f', vals(top25));
textstr{11} =   sprintf('90%%    %.2f', vals(top10));
textstr{12} =   sprintf('skew   %.2f', skewness(vals));
textstr{13} =   sprintf('kurt   %.2f', kurt);


% Place text
text(textposX, textposY, textstr, 'FontName', 'FixedWidth');


ylim = get(gca, 'ylim');
hold on 
plot( [1 1] .* vals(bot25), ylim, '-r');
plot( [1 1] .* mean(vals), ylim, '-g');
plot( [1 1] .* median(vals), ylim, '-r');
plot( [1 1] .* vals(top25), ylim, '-r');
hold off
xlabel('lines are mean (green) and quartiles (red)');

% --- Executes on button press in pushbuttonDeleteROI.
function pushbuttonDeleteROI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hpoly = getappdata(handles.figurehandle, 'roihandle');
delete(hpoly)
