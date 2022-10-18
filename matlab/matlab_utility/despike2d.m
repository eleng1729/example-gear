% This uses the outlier method in k-space as defined by
% William K. Pratt's Digital Image Processing 2nd edition
% pg 295, fig 10.3-10, and extended to three dimensions.
%BUG: Doesn't correct spikes on the outside boarders


	function outmat = spikehunt(inmat,clip);

epsilon = 5.00;          %fraction of outlier
kernalsize=3;            %size of matrix size^3
dims=size(inmat);
outmat=zeros(dims);
os=round((kernalsize-1)/2);
outmat=inmat;

for idx=2:dims(1)-1,
  for jdx=2:dims(2)-1,
      
	me = inmat(idx,jdx);
%	neighbors = mean(sum(reshape(inmat(idx-os:idx+os,jdx-os:jdx+os),kernalsize^2,1))-me);
	neighbors = reshape(inmat(idx-os:idx+os,jdx-os:jdx+os),kernalsize^2,1);
        neighbors = [neighbors(1:floor((kernalsize^2)/2));neighbors(ceil((kernalsize^2)/2)+1:kernalsize^2)];
%        neighbors(round(size(neighbors,1)+0.5),round(size(neighbors,2)+0.5))=0;
	if (((abs(me)/mean(abs(neighbors))) > epsilon) & (abs(me) > 2.0*clip(1))),
	  outmat(idx,jdx) = mean(neighbors);
        end

  end
  disp(idx);
end 
