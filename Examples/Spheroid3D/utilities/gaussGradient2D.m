function [gx,gy,gbase] = gaussGradient2D(im,sigma,siz)

% Two dimensional Gaussian gradient filter
% Smooths before taking the 1D gradients, allowing gradients of the desired
% scale to be picked out
% If only one output argument is requested, the magnitude of the gradient
% is calculated and returned, as this is the most frequent scenario
% HOWEVER, if only the x-gradient, gx, is required a second output must be
% asked for as well.

if nargin<2 || isempty(sigma)
    sigma = [1,1,1];
end

if isscalar(sigma)
    sigma = [1,1,1]*sigma;
end

if nargin<3 || isempty(siz)
    siz = max(9,odd(5*sigma,'up'));
end

if isscalar(siz)
    siz = [1,1]*siz;
end

% Gaussian smooth first, then apply the individual 1D gradients

gbase = gaussFiltND(double(im),sigma,[],siz./sigma);

% bx forms the base of gy and gz
gy = imfilter(gbase,[-1,0,1],'same','replicate');
gx = imfilter(gbase,[-1;0;1],'same','replicate');

if nargout==1
    % most likely scenario is that we only want the magnitude of the
    % gradient
    gx = sqrt(gx.^2 + gy.^2);
end

