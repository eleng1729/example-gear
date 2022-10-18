%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is my 3D complex image filter tool.
%
% This works in 3 distinctly different ways.
% If mode is "gaussian", this uses fspecial3 and imfilter. The width is
% interpreted as a width of the gaussian filter, as described in fspecial3.
%
% If the mode is median, it will separately median filter the magnitude and
% phase. Not sure if this is sensical?
%
% If the mode is anything else (sinebell, boxcar, tukey, none) it is passed
% directly to weightKspace, and the filtering is done by kspace windowing.
%
% Patrick J. Bolan, 20140117
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imgfilt = imfilter3D(img, mode, width)

if strcmpi(mode, 'gaussian')
    
    hG = fspecial3('gaussian', width);
    imgfilt = imfilter(img, hG);
    
elseif strcmpi(mode, 'median')
    
    ker = [width width];           
    imgfilt = medfilt2(abs(img), ker) .* exp(1j*medfilt2(angle(img), ker));

else
    
    % Go to K-space
    ksp = fftshift(ifftn(fftshift(img)));
    
    % Weight
    kspfilt = weightKspace(ksp, mode, width);
    
    % back to image space
    imgfilt = fftshift(fftn(fftshift(kspfilt)));
    
end