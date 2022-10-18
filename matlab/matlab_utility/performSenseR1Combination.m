function S = performSenseR1Combination(img3dmc, senscorr)

[Nro, Npe1, Npe2, Nch] = size(img3dmc);

% Make combined image S using senscorr map
S = zeros(Nro, Npe1, Npe2, 'single');
%fprintf('Perform SENSE R=1 combination\n');

% For memory reasons, loop over slice direction as well
for cdx = 1:Nch
    %fprintf('channel %d/%d\n', cdx, Nch);
    
    % Look up the 3d senscorr profile, downsampled
    % Calcs: 160x160x144*24 * 4 bytes * 2(complex) = 707MB
    % Full resolution is 8x that
    
    senscor3D = senscorr(:,:,:,cdx);
    
    % Loop over slices
    for sdx = 1:Npe2
        
        % Take the 2x downsampled 2D senscorrection and upsample it to the
        % correct resolution
        %dssenscor2D = senscor3D(:,:,ceil(sdx/fSDS2));
        %senscor2D = imresize(dssenscor2D, fSDS);
        senscor2D = senscor3D(:,:,sdx);
        
        %S(:,:,sdx) = S(:,:,sdx) + img3dmc(:,:,sdx,cdx) .* conj(senscor3D(:,:,sdx));
        S(:,:,sdx) = S(:,:,sdx) + img3dmc(:,:,sdx,cdx) .* conj(senscor2D);
    end
end