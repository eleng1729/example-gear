% When this gets called, it looks up the current point on the axes, and
% plots the T2 data
function callbackT2plot(hFig);

% Find the point clicked
cp = get(gca, 'CurrentPoint');
row = round(cp(1,2));
col = round(cp(1,1));
disp(sprintf('You clicked (x,y) = (%d, %d)', col, row));


% Pull the important data off the figure
imageset = getappdata(hFig, 'imageset');
te_vals = getappdata(hFig, 'te_vals');
T2map = getappdata(hFig, 'T2map');
M0map = getappdata(hFig, 'M0map');
Minfmap = getappdata(hFig, 'Minfmap');
T2sdmap = getappdata(hFig, 'T2sdmap');
M0sdmap = getappdata(hFig, 'M0sdmap');
Minfsdmap = getappdata(hFig, 'Minfsdmap');

% Extract data for this point
datavals = squeeze(imageset(row, col, :));
M0 = M0map(row, col);
T2 = T2map(row, col);
T2sd = T2sdmap(row, col);
M0sd = M0sdmap(row, col);

if isempty(Minfsdmap)
    Minf = 0;
    Minfsd = 0;
else
    Minf = Minfmap(row, col);
    Minfsd = Minfsdmap(row, col);
end

% Plot
plotfig = figure(122);
%movegui(plotfig, 'northeast');

% First the data
plot(te_vals, datavals, '-o');
xlabel('TE (ms)');
ylabel('Signal Amplitude');
%set(gca, 'yscale', 'log');

% Now plot the fit
hold on
sim_te = 0:1:max(te_vals(:));
plot(sim_te, M0*exp(-sim_te/T2) + Minf, ':r');
hold off
% Set the lower end to 0; use the default top end
ylim = get(gca, 'ylim');
set(gca, 'ylim', [0 ylim(2)]);
%set(gca, 'ylim', [0 M0] .* 1.1)

title(sprintf('2-param T2 Fit: M0 = %.1f +/- %.1f, T2 = %.1f +/- %.1f ms, Minf = %.1f +/- %.1f',  ...
    M0, M0sd, T2, T2sd, Minf, Minfsd));
legend('data', 'fit');





