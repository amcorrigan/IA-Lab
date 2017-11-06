function fim = gradientShift(im,kwid,gbins,offsets,numits)

% transform the image by shifting the intensity in the direction of the
% gradient.

if nargin<5 || isempty(numits)
    numits = 5;
end

% need to make sure that offsets and gbins are the right sizes
% should be one more offset than gbins
if nargin<4 || isempty(offsets)
    offsets = (-0.5:0.25:0.5)';
end
if nargin<3 || isempty(gbins)
    gbins = -0.024:0.016:0.024;
end

numbins = numel(gbins)+1;

fim = im;

[xi,yi] = ndgrid(1:numbins);
xy = [xi(:),yi(:)];
osets = offsets(xy);
for ii = 1:(numbins^2)
    iputs{ii} = {kwid,-osets(ii,:)};
end

for jj = 1:numits
    [gx,gy] = gaussGradient2D(fim,1);
    qx = imquantize(gx,gbins);
    qy = imquantize(gy,gbins);
    bins = qx + numbins*(qy-1);
    
    fim = adaptiveFilter(fim,bins,iputs,@gaussFiltOffset);
end