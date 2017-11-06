function nim = adaptNormaliseScaled(im,nhsiz,minrange,scfact)

% currently only for use with 2D images..
% this provides such a massive speed-up it might be worth implementing in
% 3D!

imstd = nanstd(im(:));

% for use on large images or with large neighbourhoods, where we can resize
% before the morphological operations.

if nargin<4 || isempty(scfact)
    scfact = 4;
end

if isscalar(scfact)
    scfact = [1,1]*scfact;
end

if nargin<3 || isempty(minrange)
    minrange = 0.1*imstd;
end

if nargin<2 || isempty(nhsiz)
    nhsiz = 40;
end
if isscalar(nhsiz)
    nhsiz = [1,1]*nhsiz;
end

nhood = diskElement(nhsiz./scfact,1,ceil(2*max(nhsiz./scfact)-1));

% normalize the image by eroding and dilating to find the maximum and
% minimum values in the neighbourhood, limited by a minimum range as
% specified by the user, either absolutely or as a fraction of the image
% standard deviation.

if minrange<1 && imstd>1
    % most likely we've specified the minrange as a fraction of the image
    % std
    minrange = minrange*imstd;
end

% need to scale the image down taking the minimum and maximum as we go
imsiz = size(im);
temp = reshape(im,[scfact(1),imsiz(1)/scfact(1),scfact(2),imsiz(2)/scfact(2)]);
temp = permute(temp,[2,4,1,3]);
temp = reshape(temp,[imsiz(1)/scfact(1),imsiz(2)/scfact(2),scfact(1)*scfact(2)]);

minsc = min(temp,[],3);
maxsc = max(temp,[],3);

minim = imerode(minsc,nhood);
maxim = imdilate(maxsc,nhood);

numim = im - resize3(minim,imsiz,'nearest');
denomim = max(minrange,maxim-minim);

nim = numim./resize3(denomim,imsiz,'nearest');
