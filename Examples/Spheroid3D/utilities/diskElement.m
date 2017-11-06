function d = diskElement(r,bin,siz)

% keep the inputs the same, but don't yet have a use for the bin input -
% perhaps average during resampling if this is not 1?
%
% otherwise, just get the distances measured from the centre.

if nargin<2 || isempty(bin)
    bin = 1;
end

if bin~=1
    error('not implemented yet..')
end

if isscalar(r)
    r = [1,1]*r;
end

if nargin<3 || isempty(siz)
    siz = 2*floor(r)+1;
end

if isscalar(siz)
    siz = [1,1]*siz;
end

midp = (siz+1)/2;

[x,y] = ndgrid(1:siz);

dmat = (((x-midp(1))/r(1)).^2 + ((y-midp(2))/r(2)).^2);

d = dmat<=1;

