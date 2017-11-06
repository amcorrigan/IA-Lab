function imout = openCloseByRecon(im,nhood)

% morphological operation to suppress small scale intensity fluctuations
%
% open by reconstruction followed by close by reconstruction operations

iobr = imreconstruct(imerode(im,nhood),im);

imout = imcomplement(imreconstruct(imcomplement(imdilate(iobr,nhood)),imcomplement(iobr)));