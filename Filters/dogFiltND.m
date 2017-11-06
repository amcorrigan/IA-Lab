function [fim,fim2,fim1] = dogFiltND(im,frad,widfact,boundcon,relsiz)

% N-dimensional DoG filtering, permuting the image rather than the
% kernel so that the filtering is always done along the first dimension,
% which seems to be faster.

if nargin<5 || isempty(relsiz)
    relsiz = 7.5; % size of the filter relative to the Gaussian radius
end
if nargin<4 || isempty(boundcon)
    boundcon = 'replicate';
end
if nargin<3 || isempty(widfact)
    widfact = 1.6;
end

if isscalar(widfact)
    widfact = widfact*ones(1,numel(frad));
end

if ~isa(im,'double')
	im = double(im);
end

% the number of elements of frad explicitly tells us how many dimensions we
% want to filter, so a scalar would mean only the x-dimension is filtered

siz = odd(relsiz.*frad,'up'); % element-wise in case we've specified different relative sizes in each dimension..
wsiz = odd(relsiz.*frad.*widfact,'up');

% need to work out which dimensions are to be permuted
totdim = numel(size(im)); % assume we won't be daft enough to use this function for low dimensional images..
ndim = numel(frad);

% allow a filter radius of zero to specify no filtering
pvect = 1:totdim;
pvect(1:ndim) = [ndim,1:(ndim-1)];

fim1 = im;
fim2 = im;
% work in reverse order
for ii = ndim:-1:1
    if frad(ii)>0
        
        % the positive part
        n = (0.55:0.1:(siz(ii)+0.45))';
        m = (1+siz(ii))/2;
        temp1 = exp(-((n-m).^2)/(2*frad(ii)^2));
        kk = sum(reshape(temp1,[10,numel(temp1)/10]),1)';
        kk = kk/sum(kk);
        
        fim1 = imfilter(permute(fim1,pvect),kk,boundcon);
        
        % and the negative part
        n = (0.55:0.1:(wsiz(ii)+0.45))';
        m = (1+wsiz(ii))/2;
        temp1 = exp(-((n-m).^2)/(2*widfact(ii)*frad(ii)^2));
        kk = sum(reshape(temp1,[10,numel(temp1)/10]),1)';
        kk = kk/sum(kk);
        
        fim2 = imfilter(permute(fim2,pvect),kk,boundcon);
        
    end
end

fim = fim1 - fim2;

