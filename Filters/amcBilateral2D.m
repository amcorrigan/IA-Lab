function fim = amcBilateral2D(im,rdata,sxy,sr,rbins,xydsc)

% fast bilateral filtering, taking advantage of MATLAB's efficiency of
% array indexing

% Adam Corrigan

% if the normalization for r-binning is done only on rg without changing
% im, we don't have to scale then rescale at the end..

% first thing to do is create a 3D image of im separated by intensity
if nargin<4 || isempty(rbins)
    rbins = 10;
end

if nargin<5 || isempty(xydsc)
    xydsc = 2; % this should really be related to the size of the xy filter
end

if isscalar(xydsc)
    xydsc = xydsc*[1,1];
end

if isempty(rdata)
    minim = double(min(im(:)));
    maxim = double(max(im(:)));
    rg = ceil(rbins*(double(im)-minim)/(maxim-minim));
else
    minim = double(min(rdata(:)));
    maxim = double(max(rdata(:)));
    rg = ceil(rbins*(double(rdata)-minim)/(maxim-minim));
end
rg(rg==0) = 1;
rg(rg>rbins) = rbins;

[xx,yy] = amcMakeGrid(im);

insiz = [size(im,1),size(im,2),rbins];
outsiz = ceil(insiz./[xydsc,1]);

if numel(sxy)==1
    sxy = [1,1]*sxy;
end

% width of the z-kernel
sb = sr*rbins;

% width of the xy-kernel in downscaled units
scxy = sxy./xydsc;

% % linind = amcSub2Ind(insiz,[xx(:),yy(:),rg(:)]);
loutind = amcSub2Ind(outsiz,[ceil([xx(:),yy(:)]./(ones(numel(xx),1)*xydsc)),rg(:)]);


% % num3 = zeros(size(im,1),size(im,2),rbins);
% % denom3 = zeros(size(num3));
% % 
% % for ii = 1:rbins
% %     ntemp = zeros(size(im));
% %     dtemp = zeros(size(im));
% %     ntemp(rg==ii) = im(rg==ii);
% %     dtemp(rg==ii) = 1;
% %     
% %     num3(:,:,ii) = ntemp;
% %     denom3(:,:,ii) = dtemp;
% % end

% % d3 = zeros(insiz);
% % n3 = zeros(insiz);
% % d3(linind) = 1;
% % n3(linind) = im(:);

% have to use the 'in' indices here because we may have duplicates in the
% 'out' indices and they need to be summed.
% The two lines below take half the total running time, can we find a
% better way? Perhaps accumarray?
% % scd = blocksum(d3,[xydsc,xydsc,1],1);
% % scn = blocksum(n3,[xydsc,xydsc,1],1);


% This can't deal with NaNs..
% scd = reshape(accumarray(loutind,ones(size(loutind)),[prod(outsiz),1]),outsiz);
% scn = reshape(accumarray(loutind,im(:),[prod(outsiz),1]),outsiz);

inds = ~isnan(im);

scd = reshape(accumarray(loutind(inds),ones(nnz(inds),1),[prod(outsiz),1]),outsiz);
scn = reshape(accumarray(loutind(inds),im(inds),[prod(outsiz),1]),outsiz);

% the rest of the running time is the actual filtering, which might be
% improved
% % fi = dog3split2([scxy,sb]);
% % fnum = gauss3filt(scn,fi);
% % fdenom = gauss3filt(scd,fi);
fnum = gaussFiltND(scn,[scxy,sb]);
fdenom = gaussFiltND(scd,[scxy,sb]);

fim = zeros(insiz(1:2));
fim(inds) = fnum(loutind(inds))./fdenom(loutind(inds));

end

function [x,y,z] = amcMakeGrid(im)

% makegrid (because it uses ndgrid) can be very memory intensive (the
% problem seems to be the permute command (line 48 of ndgrid)

% Do something about this
if numel(im)>3
    ss = size(im);
else
    ss = im;
end

if numel(ss)==1
    ss = ss*ones(1,nargout);
end

if numel(ss)==2 && nargout>2
    ss = [ss,1];
end

switch length(ss)
    case 2
%         [x,y] = ndgrid(1:ss(1),1:ss(2));
        x = repmat((1:ss(1))',[1 ss(2)]);
        y = repmat((1:ss(2)),[ss(1) 1]);
        z = ones(size(x));
    case 3
%         [x,y,z] = ndgrid(1:ss(1),1:ss(2),1:ss(3));
        x = repmat((1:ss(1))',[1 ss(2) ss(3)]);
        y = repmat((1:ss(2)),[ss(1) 1 ss(3)]);
        z = repmat(permute((1:ss(3)),[1 3 2]),[ss(1) ss(2) 1]);
end

end

function fim = gaussFiltND(im,frad,boundcon,relsiz)

% N-dimensional Gaussian filtering
% This works by permuting the image rather than the
% kernel so that the filtering is always done along the first dimension,
% which seems to be faster for some reason.

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
        
        fim = imfilter(fim,kk,boundcon);
    end
end

end

function out = odd(x,direction)

if nargin<2
	direction = 'up';
end
if ~ischar(direction)
	if direction>0
		direction = 'up';
	else
		direction = 'down';
	end
end

switch direction
	case 'up'
		out = ceil((x + 1)/2)*2 - 1;
	case 'down'
		out = floor((x + 1)/2)*2 - 1;
end

end

