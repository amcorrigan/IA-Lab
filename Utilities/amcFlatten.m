function y = amcFlatten(x)

% returns the vector form of the array x, squeezed into a single dimension
% might save a line and an intermediate variable when typing from the
% command line..

y = x(:);