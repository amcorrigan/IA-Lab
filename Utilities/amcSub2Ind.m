function idx = amcSub2Ind(sizx,inds)

% like array indexing, but in functional form to reduce temporary variables
% cluttering up the workspace
% in this function, inds is an array such as would be returned by findn

% use the same method as in sub2ind
sizx = sizx(:)';
k = [1 cumprod(sizx(1:end-1))];

idx = 1 + sum((inds-1).*(ones(size(inds,1),1)*k),2);
