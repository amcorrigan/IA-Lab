function [Lnew,probvals] = matchLabels(L2,Lseed)

% adjust the values in L2 so that they match those in the seed region.
% Try not to assume that the seed region will be wholely contained within
% L2, but that there is overlap.
%
% also, optionally check for confusion in which region is which, and flag
% this up

L3 = L2;
L3(Lseed==0) = 0;

stats = regionprops(L3,'PixelIdxList');

idxlist = {stats.PixelIdxList}';

% need to remove zeros and then check that the variance is zero and find
% the mean value

% is this any quicker than doing in a loop??
[mu,vv] = cellfun(@(x)meanvarfunction(x,Lseed),idxlist);

probvals = find(vv>0);

mu(probvals) = 0;

mu = [0;mu(:)];

Lnew = mu(L2+1);

end

function [mu,vv] = meanvarfunction(idx,L2)

vals = L2(idx);
vals(vals==0) = [];
mu = mean(vals);
vv = mean(vals.^2) - mu.^2;

end
