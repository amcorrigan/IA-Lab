function inds = logicalChoice(X,val)

% return a logical array denoting the indices of X which correspond to the
% val'th non-zero index on each row.
%
% start off by enforcing val to be the fraction, allow integers later
%
% This only works on 2D arrays, which means that multi dimensional arrays
% must be reshaped before and after calling this function
%
% If there are no non-zero elements, the last value is chosen

Y = cumsum([zeros(1,size(X,2));X>0],1);

Y = bsxfun(@rdivide,Y,max(1,Y(end,:)));
Y(end,:) = 1;

inds = logical(diff(Y>=val,1,1));
