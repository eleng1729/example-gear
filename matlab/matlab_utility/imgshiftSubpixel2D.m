% Uses interp2 to shift a 2D image
% Works for real or complex data
% Options for zerofill or wrap around edges

function imgShift = imgshiftSubpixel(img, shift, edgemode, interpmode)

[Nx, Ny] = size(img);

if nargin<3
    edgemode = 'zerofill';
end

if nargin<4
    interpmode = 'linear';
end

% Keep shifts within a single wrap
if shift(1)>Nx
    shift(1) = mod(shift(1),Nx);
end

if shift(2)>Ny
    shift(2) = mod(shift(2), Ny);
end

% Add a buffer around the image
switch edgemode
    case 'zerofill'
        imgbuf = zeros(Nx*3, Ny*3);
        imgbuf(Nx+1:2*Nx, Ny+1:2*Ny) = img;
        
    case 'wrap'                
        imgbuf = repmat(img, [3 3]);
        
    otherwise
        error('unsupported edge mode');
        
end
% This version uses interp2 to perform shifting.
[YY, XX] = meshgrid(1:Nx, 1:Ny);
[YYY, XXX] = meshgrid(-Nx+1:2*Nx, -Ny+1:2*Ny);

% Splines look very much like sinc
%imgShift = interp2(XX.', YY.', img.', XX-shift(1), YY-shift(2), 'linear', 0);
imgShift = interp2(XXX.', YYY.', imgbuf.', XX-shift(1), YY-shift(2), interpmode);

