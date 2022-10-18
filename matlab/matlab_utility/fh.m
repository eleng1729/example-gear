% This quick hides all figures
function fh
figs = get(0, 'Children');
for idx=1:size(figs)
    set(figs(idx), 'Visible','off');
end
