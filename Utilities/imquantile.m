function vals = imquantile(im,qq,nbins)

% rough quantiles of image histogram.
% the values aren't exact, because speed is much more a priority over exact
% accuracy

if nargin<3 || isempty(nbins)
    nbins = 500;
end
if nargin<2 || isempty(qq)
    qq = [0.005,0.995];
end


[counts,x] = imhist(im,nbins);
cumu = cumsum(counts);
cumu = cumu/cumu(end);

vals = zeros(size(qq));
for ii = 1:numel(qq)
    ind = find(cumu>qq(ii),1,'first');
    if isempty(ind)
        ind = nbins;
    end
    vals(ii) = x(ind);
end