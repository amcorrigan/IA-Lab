function iobr = openByRecon(im,nhood)

iobr = imreconstruct(imerode(im,nhood),im);