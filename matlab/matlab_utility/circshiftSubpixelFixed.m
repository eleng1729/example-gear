% I had never tested this with rectangular images - there was a mixing of
% the two dimensions

function imgShift = circshiftSubpixelFixed(img, shift)

% Does a 2D, complex fractional shift

% This works, but I don't really need it
% Shift is in units of pixels! 
% Need to convert to radians for this method

ksp = fftshift(fft2(ifftshift(img)));
[Nx, Ny] = size(ksp);

radshift = [shift(1)/Nx shift(2)/Ny] .* (2*pi);


% Here's the fix:
%[YY XX] = meshgrid( 1:Nx, 1:Ny);
[YY XX] = meshgrid( 1:Ny, 1:Nx);

ksp = ksp .* exp(-1j .* (radshift(1).*XX + radshift(2).*YY));

imgShift = fftshift(ifft2(ifftshift(ksp)));



