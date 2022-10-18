% This uses the outlier method in k-space as defined by
% William K. Pratt's Digital Image Processing 2nd edition
% pg 295, fig 10.3-10, and extended to three dimensions.

	function outmat = spikehunt(inmat,clip);

epsilon = 3.00;          %fraction of outlier
kernalsize=3;            %size of matrix size^3
dims=size(inmat);
outmat=zeros(dims);
os=(kernalsize-1)/2;

for idx=2:dims(1)-1,
  for jdx=2:dims(2)-1,
    for kdx=2:dims(3)-1,
	me = inmat(idx,jdx,kdx);
	neighbors = (sum(reshape(inmat(idx-os:idx+os,jdx-os:jdx+os,kdx-os:kdx+os),kernalsize^3,1))-me)/(kernalsize^3 -1);
	if (((me/neighbors) > epsilon) & (me > 2.0*clip(1))),
	  outmat(idx,jdx,kdx) = 1;
        end
    end
  end
  disp(idx);
end 
