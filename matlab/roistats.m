function roistats

h_img = findobj(gca, 'Type', 'image');

% This will prompt you to draw an ROI and will report its statistics
% Draw
h_poly = impoly;

% Mask
bw = createMask(h_poly, h_img);

img = get(h_img, 'cdata');

roi = img .* bw;
figure(100)
imagesc(roi);

vals = img(bw==1);

fprintf('roi contains %d pixels\n', max(size(vals)));
fprintf('mean %f, median %f, std %f, min %f, max %f\n', ...
    mean(vals), median(vals), std(vals), min(vals), max(vals) );

% Now report for non-zero values
nzvals = vals(vals ~=0 );
fprintf('roi contains %d non-zero pixels\n', max(size(nzvals)));
fprintf('mean %f, median %f, std %f, min %f, max %f\n', ...
    mean(nzvals), median(nzvals), std(nzvals), min(nzvals), max(nzvals) );

