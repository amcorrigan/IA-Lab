function siz = amcSize(X,ndim)

siz = ones(1,ndim);
sizX = size(X);
siz(1:numel(sizX)) = sizX;