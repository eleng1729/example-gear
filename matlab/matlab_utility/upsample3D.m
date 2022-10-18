% usage: Can be an integer scaling or explicit:
%   out = upsample3D(img, 2);
%   out = upsample3D(img, [256, 128, 60]);
%
function imgus = upsample3D(img, scaling)


if nargin<2
    scaling = 2;
end

[Nx Ny Nz] = size(img);


% Upsamples image by a scalar factor
if isscalar(scaling)
    Mx = Nx * scaling;
    My = Ny * scaling;
    Mz = Nz * scaling;
else
    % Assume the size is specified explicitly
    Mx = scaling(1);
    My = scaling(2);
    Mz = scaling(3);
end


% Go to K-space
ksp = fftshift(fftn(ifftshift(img)));
kspus = zeros(Mx, My, Mz);

%kspds = ksp(Nx/4+1:3*Nx/4, Ny/4+1:3*Ny/4, Nz/4+1:3*Nz/4);
kspus(Mx/2-Nx/2+1:Mx/2+Nx/2, My/2-Ny/2+1:My/2+Ny/2, Mz/2-Nz/2+1:Mz/2+Nz/2) = ksp(1:Nx, 1:Ny, 1:Nz);

% back to image space
imgus = fftshift(ifftn(ifftshift(kspus)));

% Scale correctly, if it's just a scaling factor
if isscalar(scaling)
    imgus = imgus .*  scaling ^3;
end
