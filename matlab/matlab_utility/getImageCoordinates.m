% 20190320 PJB
% This function creates a set of X,Y,Z coordinates from a set of dicom
% infos. These can be be then used to interpolate images onto other grid
% geometries, like this:
%
%   [Xa, Ya, Za] = getImageCoordinates(infos_a);
%   [Xb, Yb, Zb] = getImageCoordinates(infos_b);
%   imgAonB = interp3(Xa, Ya, Za, img_a, Xb, Yb, Zb);
%  You'll need to separately handle null, NaN values.
function [X, Y, Z] = getImageCoordinates(infos)

% Image coordinates, DCM coord system
info = infos{1,1,1}; % First point, should be lowest (xyz) val

rowdir = info.ImageOrientationPatient(1:3).';
coldir = info.ImageOrientationPatient(4:6).';
slcdir = cross(rowdir, coldir);

xc = info.ImagePositionPatient(1);
yc = info.ImagePositionPatient(2);
zc = info.ImagePositionPatient(3);

xd = info.PixelSpacing(1);
yd = info.PixelSpacing(2);
zd = info.SliceThickness; % Check this - sometimes wrong!

yN = info.Rows;
xN = info.Columns;
zN = size(infos,1); % 

% Hoping this is axial. 
slcdir = slcdir ./ sqrt(sum(slcdir.^2)); % Normalize
if slcdir(3) ~= 1
   % Not a typical axial volume going from foot to head 
   error('Not an standard axial volume.');
end

% Dimensions. These are the coordinates of the voxel centers. 
% Verified this logic on standard ADC
xidx = 0:1:(xN-1);
xdims = xc + double(xidx).*xd;

yidx = 0:1:(yN-1);
ydims = yc + double(yidx).*yd;

zidx = 0:1:(zN-1);
zdims = zc + double(zidx).*zd;

fprintf('\n');
fprintf('X: %d vals, delta %.3f mm, FOV %.2f mm, range (%f, %f)\n', xN, xd, xd*(xN), min(xdims(:)), max(xdims(:)));
fprintf('Y: %d vals, delta %.3f mm, FOV %.2f mm, range (%f, %f)\n', yN, yd, yd*(yN), min(ydims(:)), max(ydims(:)));
fprintf('Z: %d vals, delta %.3f mm, FOV %.2f mm, range (%f, %f)\n', zN, zd, zd*(zN), min(zdims(:)), max(zdims(:)));

% Here are 3D coords
[X, Y, Z] = meshgrid(xdims, ydims, zdims);
