% Performs 3D interplation of img_in onto the grid of img_ref
% Must be 3D
% Needs double values
% Method defaults to 'linear' (use nearest for masks)
% Note I have the confusing MESHGRID problem here, where X and Y are
% switched. I think this is due to Matlab's image/matrix convention
% PJB 20210603
function img_out = imresize3D(img_in, img_ref, method)

if nargin<3
   method = 'linear'; 
end

[b, a, c] = size(img_in); % Note b,a,c not a,b,c !!!
[X1, Y1, Z1] = meshgrid(1:a, 1:b, 1:c);

[b, a, c] = size(img_ref);
[X2, Y2, Z2] = meshgrid(1:a, 1:b, 1:c);

img_out = interp3(X1, Y1, Z1, img_in, X2, Y2, Z2, method);
