% Creates a k-space weighting function with smooth edges based on a Tukey
% (aka sin^2) window. 
%
% imsize - the size of the window
% edgewidth - The number of pixels that will get modified on the edges. No
% pixel will get multiplied by zero.
%       [startDim1, endDim1, startDim2, endDim2]
% For a discussion about weighting, see Bernstein JMRI 2001
function window = kspaceWindow2D(imsize, edgewidth)

% A cosine taper or Tukey window. See Bernstein, Handbook of MRI
% sequences, 2004. This builds up a sin^2 ramp over the transition
% band. 

% Let t go from 0 to pi/2
t = (0:(1/(edgewidth(1)+1)):1) .* (pi/2);
edgeS1 = sin(t).^2; % Define edge shape. This includes 0 and 1

t = (0:(1/(edgewidth(2)+1)):1) .* (pi/2);
edgeE1 = sin(t).^2; 

t = (0:(1/(edgewidth(3)+1)):1) .* (pi/2);
edgeS2 = sin(t).^2;

t = (0:(1/(edgewidth(4)+1)):1) .* (pi/2);
edgeE2 = sin(t).^2; 

% Make profiles for each dimension
D1 = ones(1,imsize(1));
D1(1:edgewidth(1)) = edgeS1(2:(end-1));
D1((end-edgewidth(2)+1):end) = fliplr(edgeE1(2:(end-1)));

D2 = ones(1,imsize(2));
D2(1:edgewidth(3)) = edgeS2(2:(end-1));
D2((end-edgewidth(4)+1):end) = fliplr(edgeE2(2:(end-1)));

tmpD1 = repmat(D1.', [1, imsize(2)]);
tmpD2 = (repmat(D2, [imsize(1), 1]));
window = tmpD1 .* tmpD2;



