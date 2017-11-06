function imreg = getImageRegion(im,boundingBox)

ndim = size(boundingBox,2)/2;

corner = boundingBox(:,1:ndim);
siz = boundingBox(:,(ndim+1):end);
