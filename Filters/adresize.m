function imout = adresize(im,newsize,method)


% prototype function for N-dimensional resizing

% for now just implement the 'nearest' method to get it working..

if nargin<3 || isempty(method)
    method = 'nearest';
end

% resize a 3D image, using the method specified (nearest neighbour to begin
% with)

% make a grid of the output size, scale the positions up and interpolate.

sizin = size(im);

if isempty(im)
    imout = [];
    return
end

if numel(sizin)==2
    sizin = [sizin, 1];
end

if numel(newsize)==1
    newsize = [1,1,1]*newsize;
end

% first have to make sure that newsize and sizin have the same number of
% dimensions

if numel(newsize)>numel(sizin)
    temp = ones(1,numel(newsize));
    temp(1:numel(sizin)) = sizin;
    sizin = temp;
elseif numel(sizin)>numel(newsize)
    temp = ones(1,numel(sizin));
    temp(1:numel(newsize)) = newsize;
    newsize = temp;
end

newsize(newsize<=1) = sizin(newsize<=1).*newsize(newsize<=1);

if numel(newsize)<3
    newsize = [newsize,1];
end

newsize = ceil(newsize);


% assuming memory is not a limitation, we can resize using linear indexing


switch lower(method)
    case 'nearest'
        outsub = amcInd2Sub(newsize,(1:prod(newsize))');
        
        insub = round(0.5+(outsub-0.5).*repmat(sizin./newsize,[size(outsub,1),1]));
        
        insub = max(1,min(insub,repmat(sizin,[size(outsub,1),1])));
        
        imout = reshape(im(amcSub2Ind(sizin,insub)),newsize);
        
        
    otherwise
        error('Not implemented yet')
end

