function fim = gaussNaNFilt(im,frad,boundcon,relsiz)

% N-dimensional Gaussian filtering, permuting the image rather than the
% kernel so that the filtering is always done along the first dimension,
% which seems to be faster.
%
% This version allows for NaNs to be in the image, using nanfilter rather
% than imfilter.

if nargin<4 || isempty(relsiz)
    relsiz = 6; % size of the filter relative to the Gaussian radius
end
if nargin<3 || isempty(boundcon)
    boundcon = 'replicate';
end

if ~isa(im,'double')
	im = double(im);
end

% the number of elements of frad explicitly tells us how many dimensions we
% want to filter, so a scalar would mean only the x-dimension is filtered

siz = odd(relsiz.*frad,'up'); % element-wise in case we've specified different relative sizes in each dimension..

% need to work out which dimensions are to be permuted
totdim = numel(size(im)); % assume we won't be daft enough to use this function for low dimensional images..
ndim = numel(frad);

% allow a filter radius of zero to specify no filtering
pvect = 1:totdim;
pvect(1:ndim) = [ndim,1:(ndim-1)];

fim = im;
% work in reverse order
for ii = ndim:-1:1
    fim = permute(fim,pvect);
    
    if frad(ii)>0
        n = (0.55:0.1:(siz(ii)+0.45))';
        m = (1+siz(ii))/2;
        temp1 = exp(-((n-m).^2)/(2*frad(ii)^2));
        kk = sum(reshape(temp1,[10,numel(temp1)/10]),1)';
        kk = kk/sum(kk);
        
        fim = nanfilter(fim,kk,'same',boundcon);
    end
end

