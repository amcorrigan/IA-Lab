function normim = labelRangeNormalise(im,L,minrange,zeroval)

% don't know if this is the quickest way of doing this..

if nargin<4
    zeroval = []; % leave with NaNs by default
end
if nargin<3 || isempty(minrange)
    minrange = 0.1;
end

if minrange<1
    imrange = max(im(:)) - min(im(:));
    if imrange>1
        minrange = minrange*imrange;
    end
end

stats = regionprops(L,im,'MinIntensity','MaxIntensity');

minval = field2val2(stats,'MinIntensity');
minval(isnan(minval)) = 0;

maxval = field2val2(stats,'MaxIntensity');
maxval(isnan(maxval)) = 0;



minim = propimage(L,minval);
maxim = propimage(L,maxval);
normim = (im - minim)./max((maxim-minim),minrange);

if ~isempty(zeroval)
    normim(isnan(normim)) = zeroval;
end