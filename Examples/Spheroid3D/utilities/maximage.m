function [iix,val] = maximage(im)

% return the index of the maximum value of the image in the last dimension.
% Useful for looking at the outputs of a bunch of filters and picking the
% one with the largest response, for example.

sizim = size(im);

dim = find(size(im)>1,1,'last');

if dim>2
    % reshape into 2D
    im = reshape(im,[prod(sizim(1:(dim-1))),sizim(dim)]);
end

% sort
[vv,iix] = sort(im,2,'descend');

if dim>2
    iix = reshape(iix(:,1),sizim(1:dim-1));
end
if nargout>1
    if dim>2
        val = reshape(vv(:,1),sizim(1:dim-1));
    else
        val = vv(:,1);
    end
end

