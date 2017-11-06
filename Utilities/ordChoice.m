function Y = ordChoice(X,val,dim)

% return a logical array denoting the indices of X which correspond to the
% val'th non-zero index on each row.
%
% start off by enforcing val to be the fraction, allow integers later
%
% multi dimensional arrays must be reshaped at the start and end
%
% If there are no non-zero elements, the last value is chosen

if nargin<3 || isempty(dim)
    dim = numel(size(X));
end

% need to permute so that the required dimension is at the end

ndim = max(numel(size(X)),dim);
sizX = amcSize(X,ndim);
ord = 1:ndim;
shiftval = ndim-dim;
permord = circshift(ord,[0,shiftval]);

permsiz = circshift(sizX,[0,shiftval]);

X = reshape(permute(X,permord),[prod(permsiz(1:end-1)),permsiz(end)])';
% X is now 2-dimensional

inds = logicalChoice(X,val);

Y = X(inds);

% then reshape and permute Y back to the original dimensions (minus the one
% that we've selected)

Y = reshape(Y,permsiz(1:end-1));
revpermord = circshift(ord(1:end-1),[0,-shiftval]);

Y = permute(Y,revpermord);