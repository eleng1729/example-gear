% This quick function brings all figures to the front 
function fs
figs = get(0, 'Children');
for idx=1:size(figs)
   figure(figs(idx)); 
end
