function fg2 = mergeForegroundPoints(fg,nhood,useWeighted)

% merge foreground regions (typically local maxima pixels) together if they
% are closer than a threshold distance (determined by nhood)
%
% Do this by dilation followed by centroid location
% this will have the effect of moving points out from the boundary, and
% does not guarantee that the new point will be the average of all
% contributing regions - if that is required, do a weighted centroid based
% on the original pixels.

if nargin<3 || isempty(useWeighted)
    useWeighted = true;
end

if isscalar(nhood)
    nhood = diskElement(nhood);
end

dilim = imdilate(fg,nhood);

if useWeighted
    stats = regionprops(dilim>0,fg>0,'WeightedCentroid');
    xyz = cell2mat({stats.WeightedCentroid}');
else
    stats = regionprops(dilim>0,'Centroid');
    xyz = cell2mat({stats.Centroid}');
end

xyz = round(xyz(:,[2,1,3:end]));

linind = amcSub2Ind(size(fg),xyz);

fg2 = false(size(fg));
fg2(linind) = true;
