function [imout,lims] = rangeNormalise(imin)

if isa(imin,'integer')
	imin = double(imin);
end

lims = [min(imin(:)),max(imin(:))];

denom = lims(2) - lims(1);
num = (imin - lims(1));

if denom~=0
    imout = num/denom;
else
    if max(imin(:))>0
        imout = ones(size(imin));
    else
        imout = zeros(size(imin));
    end
end