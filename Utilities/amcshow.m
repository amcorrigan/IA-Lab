function varargout = amcshow(im,cmap)

if nargin<2 || isempty(cmap)
    cmap = 'jet';
end

imh = imagesc(im);
colormap(cmap)
daspect([1,1,1])

if nargout>0
    varargout{1} = imh;
end
