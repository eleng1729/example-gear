% usage: Can be an integer scaling or explicit:
%   out = downsample3D(img, 2);
%   out = downsample3D(img, [128, 32, 16]);
%
function imgds = downsample3D(img, scaling)

if nargin<2
    scaling = 2;
end

% Downsamples image by a scalar factor
[Nx Ny Nz] = size(img);

% Upsamples image by a scalar factor
if isscalar(scaling)
    Mx = Nx / scaling;
    My = Ny / scaling;
    Mz = Nz / scaling;
else
    % Assume the size is specified explicitly
    Mx = scaling(1);
    My = scaling(2);
    Mz = scaling(3);
end

% Go to K-space
ksp = fftshift(fftn(ifftshift(img)));


%kspds = ksp(Nx/4+1:3*Nx/4, Ny/4+1:3*Ny/4, Nz/4+1:3*Nz/4);
kspds = ksp(Nx/2-Mx/2+1:Nx/2+Mx/2, Ny/2-My/2+1:Ny/2+My/2, Nz/2-Mz/2+1:Nz/2+Mz/2);

% back to image space
imgds = fftshift(ifftn(ifftshift(kspds)));

% Scale correctly, if it's just a scaling factor
if isscalar(scaling)
    imgus = imgus ./ scaling ^3;
end
