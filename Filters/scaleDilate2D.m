function im2 = scaleDilate2D(im,nhsiz,scfact)

% perform a fast dilation by first shrinking the image taking the maxima
% for each region, then performing a separable dilation in x-y and z.

% 2D version

if nargin<2 || isempty(nhsiz)
    nhsiz = 40;
end
if isscalar(nhsiz)
    nhsiz = [1,1]*nhsiz;
end

if nargin<3 || isempty(scfact)
    scfact = 2;
end
if isscalar(scfact)
    scfact = [1,1]*scfact;
end

scfact(nhsiz<=1) = 1;

% imsiz = [size(im,1),size(im,2),size(im,3)];
imsiz = [size(im,1),size(im,2)];

tsiz = scfact.*(ceil(imsiz./scfact));

tempim = zeros(tsiz);

tempim(1:imsiz(1),1:imsiz(2)) = im;


rr = nhsiz(1:2)./scfact(1:2);
% ss = ceil(2*max(nhsiz(1:2)./scfact(1:2))-1);
rr = max(rr,1.4);
% ss = max(ss,3);
% nhood = diskElement(rr,1,ss);
nhood = diskElement(rr,1);

temp = reshape(tempim,[scfact(1),tsiz(1)/scfact(1),scfact(2),tsiz(2)/scfact(2)]);
temp = permute(temp,[2,4,1,3]);
temp = reshape(temp,[tsiz(1)/scfact(1),tsiz(2)/scfact(2),scfact(1)*scfact(2)]);

maxsc = max(temp,[],3);

maxim = imdilate(maxsc,nhood);

im2 = adresize(maxim,imsiz,'nearest'); % also possible to use linear here for grayscale images?

