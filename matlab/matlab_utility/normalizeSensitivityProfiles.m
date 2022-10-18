function sensNorm = normalizeSensitivityProfiles(senscorr)

% rescales sensitivity profiles so they are "fractional" or normalized.
% This is necessary (I think) for SENSE1 recon, otherwise you double-scale
% by the amplitude.
sensNorm = senscorr .* 0;

% Must be a 3D image. If you have a 2D, reshape it

% 3D
[Nro, Npe1, Npe2, Nch] = size(senscorr);
senssum = sum(abs(senscorr),4);
% For memory reasons, loop over slice direction as well
for cdx = 1:Nch
    for sdx = 1:Npe2
        sensNorm(:,:,sdx,cdx) = senscorr(:,:,sdx,cdx) ./ senssum(:,:,sdx);
    end
end

% if sum = 0, you'll get NaNs
sensNorm(isnan(sensNorm)) = 0;

