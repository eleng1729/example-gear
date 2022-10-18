% Links all subplots in the specified figure
function linkSubplots(hFig)

if nargin<1
    hFig = gcf;
end

% Find all the axes of this figure, add their handles to 'ax' array
children = get(hFig, 'Children');
ax = [];
for idx=1:size(children,1);
    h = children(idx);
    % Interestingly, colorbars are also axes
    if (strcmpi(get(h, 'type'), 'axes')==1) && strcmpi(get(h,'Tag'), 'Colorbar')~=1
        ax = [ax children(idx)];
    end
end

% link'em
if ~isempty(ax)
   linkaxes(ax); 
end