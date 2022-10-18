% This tightens up all figures
% The Boolean 'bBars' determines whether or not to show the tool and
% menubars
function ftt(bBars)
figs = get(0, 'Children');

if nargin<1
   bBars = true;
end

if ~bBars
   fprintf('Menu and toolbars disabled. Call ''ftt(true)'' to re-enable.\n');
end

for idx=1:size(figs)
    
    % Disable menubar
    if bBars
    set(figs(idx), 'Toolbar', 'figure');
    set(figs(idx), 'MenuBar', 'figure');
    else
    set(figs(idx), 'Toolbar', 'none');
    set(figs(idx), 'MenuBar', 'none');
    end
    tightfig(figs(idx));
end

% Then tile them
ft