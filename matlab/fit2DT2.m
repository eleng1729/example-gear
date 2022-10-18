%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function will fit a series of 2D images, pixel-by-pixel, to a
% exponential decay curve. The equation is:
%
%   S(te) = M0 * exp(-TE/T2) + Minf
%
% This is an approximation, as it doesn't have a TE=Inf term to account for
% noise.
% To processes 3D or multislice sets, call this once per slice.
% Arguments:
%   imageset - a 3D array, with dimensions (Nx, Ny, Nte)
%   mask - a 2D bitmap with dimensions (Nx, Ny). Fits are calculated for
%       pixels == 1, T2 and M0 are set to 0 for mask==0
%   te_vals - an array of TEs, 1xNte. Units should be ms
% Return values:
%   T2map - a double-valued array (Nx, Ny) of T2 values, in ms units
%   M0map - the fit M0 map.
%   Minf - the signal at infinity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tip: calculate a mask like this, where img is the 3rd image in the set:
%   mask(img(:)<threshold) = 0;
%   mask(img(:)>=threshold) = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [T2map, M0map, T2sdmap, M0sdmap, Minfmap, Minfsdmap] = ...
    fit2DT2(imageset, mask, te_vals, model, TolX, TolFun)

[Nx, Ny, Nte] = size(imageset);

% estimate noise floor
noiselevel = estimate_noise_from_2D_timeseries(imageset);
%noiselevel = estimate_noise_from_2D_expdecayseries(imageset, te_vals);

% Check that the mask is the right size
[Nxm, Nym] = size(mask);
if( (Nx ~= Nxm) || (Ny ~= Nym))
    error('Mismatched arrays:  imageset=[%s]; mask=[%s]', ...
        num2str(size(imageset)), ...
        num2str(size(mask)));
end

% Check that the te_vals is a vector of te correct size
if(size(te_vals, 2) ~= Nte)
    if( (size(te_vals,1) == Nte) & (size(te_vals, 2) == 1))
        warning('te_vals is a row vector; pass in a column vector for better performance');
        te_vals = te_vals';
    else
        error('Mismatched TE values:  imageset=[%s]; te_vals=[%s]', ...
            num2str(size(imageset)), ...
            num2str(size(te_vals)));
    end
end


% Pre-allocate the output values
T2map = zeros(Nx, Ny);
M0map = zeros(Nx, Ny);
T2sdmap = zeros(Nx, Ny);
M0sdmap = zeros(Nx, Ny);
Minfmap = zeros(Nx, Ny);
Minfsdmap = zeros(Nx, Ny);


% Select fitting function based on model
switch model
    case 'linear'
        fitfunc = @fit_to_exp_decay_2param_linear;
        estfitrate = 10000;
        
    case 'exp2'
        fitfunc = @fit_to_exp_decay_2param;
        estfitrate = 18;

    case 'exp2+noise'
        % Include the fixed Rician temporal noise to the model
        fitfunc = @fit_to_exp_decay_2param_fixednoise;
        estfitrate = 18;
        
    case 'exp3'
        % Fit the Rician temporal noise within the model
        fitfunc = @fit_to_exp_decay_3param;
        estfitrate = 16;
        
    otherwise
        fprintf('Fit model not specified, using linear\n');
        fitfunc = @fit_to_exp_decay_2param_linear;
        estfitrate = 10000;
end
fprintf('Fitting model: %s\n', model);    

% Calculate the mask size
num_fits = (sum(mask(:)));
disp(sprintf('Fitting %d of %d pixels (%.1f%%)', ...
    num_fits, (Nx*Ny), num_fits/(Nx*Ny)*100));
disp(sprintf('Estimating %d fits/second (per-core), time required ~%.1f minutes', ...
    estfitrate, ...
    (num_fits/estfitrate)/60 ));

% User-configurable fit tolerances, which often need to be tuned
if isempty(TolX)
    TolX = 1e-6;
end
if isempty(TolFun)
    TolFun = 1e-6;
end

% Debugging
bShowFitting = 0;

% Iterate over all and fit if mask == 0
start_time = tic;
for xdx = 1:Nx    
    for ydx = 1:Ny
        if (mask(xdx, ydx)==1)
            % Fit this pixel
            %disp(sprintf('Fitting (%d, %d)\n', xdx, ydx));
            [M0, R2, M0sd, R2sd, Minf, Minfsd] = fitfunc(...
                te_vals, squeeze(imageset(xdx, ydx, :)), ...
                noiselevel, TolFun, TolX, bShowFitting);
            
            %fprintf('M0 %f (%f); T2 %f (%f); Minf %f (%f)\n',...
            %    M0, M0sd, 1/R2, R2sd / R2^2, Minf, Minfsd);
            
            % Reject bad fits.
            % If the error estimate of the T2 or S0 is >=100%, then reject
            T2accuracy = R2sd/R2^2 / (1/R2);
            M0accuracy = M0sd / M0;
%             if (T2accuracy > 1) || (M0accuracy > 1)
%                 M0 = 0;
%                 R2 = Inf;
%                 M0sd = 0;
%                 R2sd = 0;
%                 Minf = 0;
%                 Minfsd = 0;
%             end
            
            if ~isfinite(M0) || ~isfinite(R2) || ~isfinite(Minf)
                M0 = 0;
                R2 = Inf;
                M0sd = 0;
                R2sd = 0;
                Minf = 0;
                Minfsd = 0;                
            end     
            
            T2map(xdx, ydx) = 1/R2;
            M0map(xdx, ydx) = M0;
            % sigT/T = sigR/R, R=1/T, ==> sigT = sigR/R^2
            T2sdmap(xdx, ydx) = R2sd / R2^2;
            M0sdmap(xdx, ydx) = M0sd;      
            
            Minfmap(xdx, ydx) = Minf;
            Minfsdmap(xdx, ydx) = Minfsd;
        end
    end    
end
total_seconds = toc(start_time);
fprintf('Fitting completed in %.1f minutes (%.1f seconds)\n', ...
    total_seconds/60, total_seconds);




