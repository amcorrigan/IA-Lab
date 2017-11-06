function lmax = scaleRegionalMaxima2D(im,nhsiz,scfact,epsilon)

% my version of the regional maxima function which looks at the custom
% surrounding neighbourhood rather than defining connectivity

% 2D version, reducing the amount of permuting required.

if nargin<4 || isempty(epsilon)
    epsilon = 0.001;
end
if nargin<3 || isempty(scfact)
    scfact = 2;
end

if isscalar(scfact)
    scfact = scfact*ones(1,numel(nhsiz));
end

stdval = amcStd(im(:));

if any(nhsiz)<=1
    nhsiz(nhsiz<=1) = 1;
    scfact(nhsiz<=1) = 1;
end

dilim = scaleDilate2D(im,nhsiz,scfact);

if ~isnan(epsilon)
    lmax = im>(dilim-epsilon*stdval);
else
    lmax = im==dilim;
end

