function maxdiameter = polydiameter(x,y)
%POLYDIAMETER Area of polygon.
%   POLYDIAMETER(X,Y) returns the maximum diameter of the polygon defined
%   by the vertices in vectors X and Y. Alternatively, consider this the
%   diameter of the smallest enclosing circle.
% 
%   This implementation is brute force. There is probably a faster method
%   by measuring lengths to one point (or centroid?).
%
%   Modeled off of Matlabs polyarea, but written by Patrick Bolan, 2011/3/6

if nargin==1 
  error('polydiameter:NotEnoughInputs', 'Not enough inputs.'); 
end

if ~isequal(size(x),size(y)) 
  error('polydiameter:XYSizeMismatch', 'X and Y must be the same size.'); 
end

% Brute force: find the two points that are maximally far apart by looking
% at all comparisons.
pts = max(size(x(:)));
maxdiameter = 0;
for idx=1:pts-1
    for jdx=idx+1:pts
       dia = sqrt( (x(idx) - x(jdx))^2 + (y(idx) - y(jdx))^2 );
       maxdiameter = max(maxdiameter, dia);
    end
end

