% Finds the center of a 3D kspace

function center = findKSpaceCenter(ksp)
center = [0 0 0];

% For each of the 3 dimensions, sum the other 2, and then find the max
% point.

% Dim 1
proj1 = squeeze(sum(abs(ksp),2));
proj2 = squeeze(sum(proj1,2));
idx = find(proj2 == max(proj2(:)));
center(1) = idx(1); % There could be multiples

% Dim 2
proj1 = squeeze(sum(abs(ksp),1));
proj2 = squeeze(sum(proj1,2));
idx = find(proj2 == max(proj2(:)));
center(2) = idx(1); % There could be multiples

% Dim 3
proj1 = squeeze(sum(abs(ksp),1));
proj2 = squeeze(sum(proj1,1));
idx = find(proj2 == max(proj2(:)));
center(3) = idx(1); % There could be multiples



