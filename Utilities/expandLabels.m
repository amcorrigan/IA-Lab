function L2 = expandLabels(L,distval)

% expand the labels outwards using a watershed of a distance transform
% This is reliant on the initial seeds not touching each other - if this is
% the case we'll need to check and shrink them inwards first
%
% Probably quicker ways of doing this, but this does it the way we want for
% now

D = bwdist(L>0);

W = watershed(D);

% reorder so that the expanded regions match the originals

Ltemp = W;
Ltemp(L==0) = 0;
% reorder so that the values of L and L0 are matched
stats = regionprops(Ltemp,L,'MeanIntensity');
idx = [0;[stats.MeanIntensity]'];

L2 = idx(W+1);

if nargin>1 && ~isempty(distval)
    L2(D>distval) = 0;
end