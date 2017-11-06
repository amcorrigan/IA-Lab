function fim = amcBilat(im,rdata,sxy,sr,rbins,xydsc)

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

[xx,yy] = makegrid2(im);

insiz = [size(im,1),size(im,2),rbins];
outsiz = ceil(insiz./[xydsc,1]);

if numel(sxy)==1
    sxy = [1,1]*sxy;
end

% width of the z-kernel
sb = sr*rbins;

% width of the xy-kernel in downscaled units
scxy = sxy./xydsc;

% % linind = adsub2ind(insiz,[xx(:),yy(:),rg(:)]);
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
fnum = gnfilt(scn,[scxy,sb]);
fdenom = gnfilt(scd,[scxy,sb]);

fim = zeros(insiz(1:2));
fim(inds) = fnum(loutind(inds))./fdenom(loutind(inds));

