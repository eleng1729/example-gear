% My own montage.
% Matlab's montage() is a complicated function that does scaling, loading
% from files, etc. I just need a simpler one.

function imgMontage = montage2(img3d)

[Nx, Ny, Nch] = size(img3d);

% Montage over the 3rd dimension
cols = round(sqrt(Nch));
rows = ceil(Nch/cols);

%fprintf('%d rows x %d cols\n', rows, cols);

imgMontage = zeros(Nx*rows, Ny*cols);
cnt = 0;
for rdx = 1:rows
    for cdx = 1:cols
        cnt = cnt + 1;        
        if cnt > Nch
            break;
        end        
        
        xrange = (1:Nx) + Nx*(rdx-1);
        yrange = (1:Ny) + Ny*(cdx-1);
        imgMontage(xrange,yrange) = img3d(:,:,cnt);
        
        % Animates, so you can see it goes R.. L first
        %figure(19)
        %imagesc(imgMontage);
        %pause(.5);

    end
    
end



