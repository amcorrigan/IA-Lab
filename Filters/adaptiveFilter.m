function fim = adaptiveFilter(im,rdata,kernels,optionstr)

% split the image based on which bin it belongs to in rdata, filter each
% layer separately and then recombine.
% Not sure if the numerator denominator needs to be done, find out later..
%
% try without downscaling first?
% because otherwise the kernels will need to be scaled appropriately too

% if this works it can form the basis of the gradient diffusion approach

% use optionstr to specify a number of options - for instance if we want to
% do gaussian blurring using the faster gaussFiltND function (or test the
% fspecial version)

if isempty(rdata)
    minim = double(min(im(:)));
    maxim = double(max(im(:)));
    rdata = ceil(numel(kernels)*(double(im)-minim)/(maxim-minim));
    rdata(rdata==0) = 1;
    rdata(rdata>numel(kernels)) = numel(kernels);
end

[xx,yy] = amcMakeGrid(im);
insiz = [size(im,1),size(im,2),numel(kernels)];

loutind = amcSub2Ind(insiz,[xx(:),yy(:),rdata(:)]);

zim = zeros(insiz);
zim(loutind) = im(:);

% now do the filtering
% this could potentially be parallelized?

% optionstr could be a function handle, and kernels{ii} is the varargin for
% it
for ii = 1:numel(kernels)
    if nargin<4 || isempty(optionstr)
        zim(:,:,ii) = imfilter(zim(:,:,ii),kernels{ii});
    elseif strcmpi(optionstr,'gauss')
        zim(:,:,ii) = gaussFiltND(zim(:,:,ii),kernels{ii});
    elseif isa(optionstr,'function_handle')
        if ~iscell(kernels{ii})
            kernels{ii} = kernels(ii);
        end
        zim(:,:,ii) = optionstr(zim(:,:,ii),kernels{ii}{:});
    else
        error('option not implemented yet')
    end
end

% recombine at the end
fim = sum(zim,3);
