
% Removes the linear phase in an object by centering kspace. 
% This works on an array of 3D images, using the first one to find the
% center of kspace and applying that to the rest. Also just works with a 3D
% image
function [Sout, kspoffset] = removeLinearImagePhase(img4d, kspoffset)

if nargin<2
    % Need to calculate the kspace offset
    
    ksp = fftshift(fftn(ifftshift(img4d(:,:,:, 1))));
    measuredCenter = findKSpaceCenter(ksp);
    correctCenter = size(ksp)./2 + 1;
    kspoffset = correctCenter - measuredCenter;
end

% This takes a complex image, goes back to kspace, centers kspace, and then
% back to image space

fprintf('Shifting kspace by [%d %d %d] pixels\n', kspoffset);

Sout = img4d.*0;
for idx=1:size(img4d,4)
    ksp = fftshift(fftn(ifftshift(img4d(:,:,:, idx))));
    Sout(:,:,:, idx) = fftshift(ifftn(ifftshift(circshift(ksp, kspoffset))));
end