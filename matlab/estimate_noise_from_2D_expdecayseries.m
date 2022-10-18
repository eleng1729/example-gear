% When you're fitting a pixel for T2 decay, you need to know what the value
% at TE=infinity is. This is not, however, thermal noise; it is the
% phyisological noise + thermal (Rician) noise. This function seeks to
% estimate this value.

% The idea here is to remove most of the "effect", and then look at the
% TE variation of what is left. This is the TE-noise. It comes from thermal
% noise, plus all sorts of other stuff (motion, PE ghosts, stim echoes,
% etc). It is spatially varying, and includes those pixels with only
% thermal noise, as well as those that were fit poorly. We take the median
% to avoid 

function noiselevel = estimate_noise_from_2D_expdecayseries(imageset, te_vals)

% Imageset should be (rows, columns, timepoint)
[rows, cols, pts] = size(imageset);

% First, do a linear over all pixels to estimate the MO and T2
M0map = zeros(rows, cols);
R2map = zeros(rows, cols);
Ssim = zeros(rows, cols);
for xdx = 1:rows
    for ydx = 1:cols
        
        [M0, R2, M0sd, R2sd, Minf, Minfsd] = fit_to_exp_decay_2param_linear(...
            te_vals, squeeze(imageset(xdx, ydx, :)), ...
            [], [], [], 0);
        M0map(xdx, ydx) = M0;
        R2map(xdx, ydx) = R2; 
    end
end

% Now simulate Ssim
for tdx = 1:pts
   Ssim(:,:,tdx) = M0map(:,:) .* exp(-te_vals(tdx).*R2map(:,:));  
end

% Subtract this off of the original data. What's left is the variation that
% is not described by a simple linear exponential decay.
residual = imageset - Ssim;

% Now take the standard deviation of each pixel over the TE direction.
stdimg = std(residual, 1, 3);

% In an ideal world, all you would be left with is noise. 
noiselevel = median(stdimg(:));

% An interesting plot, which if the fit were perfect and the noise were
% only thermal, would be the cumulative distribution of the gaussian 
% thermal noise:
%plot(sort(stdimg(:));
