function icbr = closeByRecon(im,nhood)

icbr = imcomplement(imreconstruct(imcomplement(imdilate(im,nhood)),imcomplement(im)));