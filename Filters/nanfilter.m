function fim = nanfilter(im,kk,arg1,arg2)

% perform filtering, attempting to ignore the effect of NaNs in the image,
% and prevent them propagating.  The precise implementation of the filter
% using numerator and denominator images may not be mathematically rigorous
% in certain circumstances.

% this will be slowing than simply filtering with imfilter, because two
% filtering operations are required.

if nargin<3 || isempty(arg1)
    arg1 = 'same';
end
if nargin<4 || isempty(arg2)
    arg2 = 'replicate';
end

inds = cast(isfinite(im),'like',im); % cast the logical array as the same class as im.

kk = cast(kk,'like',im);

denom = imfilter(inds,kk,arg1,arg2);
im(~inds) = 0;
num = imfilter(im,kk,arg1,arg2);

fim = num./denom;


