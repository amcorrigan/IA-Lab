function y = arraySliceReference(x,varargin)

% in-line version of slice referencing
% 
% like array indexing, but in functional form to reduce temporary variables
% cluttering up the workspace
% Examples - 
% arraySliceReference(x,inds1,inds2) produces x(inds1,inds2) as the output

if isempty(x)
    y = zeros(0,size(x,2));
    return
end

% special case of a row vector
if isrow(x) && length(varargin)==1
    y = x(varargin{1});
    return
end

sizx = size(x);
ndim = numel(size(x));
for ii = 1:ndim
    if ii>length(varargin) || isempty(varargin{ii})
        inds{ii} = 1:sizx(ii);
    else
        inds{ii} = varargin{ii};
    end
end

switch ndim
    case 2
        y = x(inds{1},inds{2});
    case 3
        y = x(inds{1},inds{2},inds{3});
    case 4
        y = x(inds{1},inds{2},inds{3},inds{4});
    case 5
        y = x(inds{1},inds{2},inds{3},inds{4},inds{5});
    case 6
        y = x(inds{1},inds{2},inds{3},inds{4},inds{5},inds{6});
end
