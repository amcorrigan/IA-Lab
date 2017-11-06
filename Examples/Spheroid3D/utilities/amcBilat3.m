function fim = amcBilat3(im,rdata,sxyz,sr,rbins,xyzdsc)

% fast bilateral filtering, taking advantage of MATLAB's efficiency of
% array indexing
% Modified to handle 3D input images

% Adam Corrigan

% first thing to do is create a 3D image of im separated by intensity
if nargin<4 || isempty(rbins)
    rbins = 10;
end

if nargin<5 || isempty(xyzdsc)
    xyzdsc = 2; % this should really be related to the size of the xy filter
end
if isscalar(xyzdsc)
    xyzdsc = [1,1,1]*xyzdsc;
end

if isscalar(sxyz)
    sxyz = [1,1,1]*sxyz;
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

% is there a quicker way of generating the downscaled indices?
% use sub2ind or similar?
[xx,yy,zz] = makegrid2(im);

insiz = [size(im,1),size(im,2),size(im,3),rbins];
outsiz = ceil(insiz./[xyzdsc,1]);

% width of the z-kernel
sb = sr*rbins;

% width of the xy-kernel in downscaled units
scxyz = sxyz./xyzdsc;

loutind = amcSub2Ind(outsiz,[ceil([xx(:)/xyzdsc(1),yy(:)/xyzdsc(2),zz(:)/xyzdsc(3)]),rg(:)]);
% Since the intensity info will always be the last dimension, we can
% directly calculate the final linear index.
% But what about the effect of downscaling xx,yy and zz? Can we calculate
% that? Just leave as it is for now..

inds = ~isnan(loutind);
try
scd = reshape(accumarray(loutind(inds),ones(size(loutind(inds))),[prod(outsiz),1]),outsiz);
scn = reshape(accumarray(loutind(inds),im(inds),[prod(outsiz),1]),outsiz);
catch ME
    keyboard
end
fnum = gaussFiltND(scn,[scxyz,sb]);
fdenom = gaussFiltND(scd,[scxyz,sb]);

if nnz(~inds)==0
    fim = reshape(fnum(loutind)./fdenom(loutind),insiz(1:3));
else
    % need to construct fnum and fdenom a little differently
    
    loutind = loutind + 1;
    loutind(~inds) = 1;
    
    fnum = [NaN;fnum(:)];
    fdenom = [NaN;fdenom(:)];
    
    fim = reshape(fnum(loutind)./fdenom(loutind),insiz(1:3));
    
end

% don't think this is required any longer?
% fim = fim*(maxim-minim) + minim;

