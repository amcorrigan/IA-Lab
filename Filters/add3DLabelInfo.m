function L3 = add3DLabelInfo(L2,im,seedL,gradim,vectgrad,removeDodgy,smoothScale)

% Take the 2D label matrix and expand each column into 3D
% The z gradient particularly gets very small around the edges - unless
% something can be done about this we might have to artificially impose
% smaller heights 1 or two pixels from the boundary..
%
% This version uses a smaller 3D seed region, which must be fully contained
% within the 3D label array.

if nargin<7 || isempty(smoothScale)
    smoothScale = 8; % the xy size of discontinuities (eg nucleoli) to be morphologically smoothed
end
if nargin<6 || isempty(removeDodgy)
    removeDodgy = 0; %by default don't modify the 2D label array
end
if nargin<5 || isempty(vectgrad)
    vectgrad = 0; % assume we only have the absolute value of the gradient by default, not its direction.
end

% better to keep this empty until it's needed!
% % if nargin<3 || isempty(seedL)
% %     seedL = zeros(size(im));
% % end

if nargin<3
    seedL = [];
end


% tstats = regionprops(L2,'Centroid','PixelIdxList');
% The centroid isn't guaranteed to fall inside the region!

if nargin<4 || isempty(gradim)
    bg = bwmorph(L2==0,'skel',Inf);

    nucl = im(:,:,1);
    try
        bgl = nanmean(nucl(bg));
    catch ME
        rethrow(ME)
    end


    nucu = im(:,:,end);
    bgu = nanmean(nucu(bg));

% % if nargin<4 || isempty(gradim)
    temp = cat(3,bgl*ones(size(L2)),im,bgu*ones(size(L2)));
    gradim = temp(:,:,3:end) - temp(:,:,1:end-2);
end

% L3 = zeros(size(im));

% xyz = zeros(numel(tstats),3);

% can perhaps find the global slice maxima using filtering operations and
% then use these for the region operations
% % if size(im,3)>50
% %     zsc = 3;
% %     zfact = 2;
% % else
% %     zsc = 1.5;
% %     zfact = 1;
% % end

% % im = amcBilat3(gaussFiltND(im,[1,1,0.5]),[],[4,4,zsc],0.04,16,[4,4,zfact]);
% try saving a bit of time here
% if we want blurring done, it should be done outside of this function..
% im = gaussFiltND(im,[3,3,2]);

% flag as dodgy xy columns for which the max pixel is more than 2.2 s.d.
% from the mean height
iix = imageMaxIndex(im);
dodgy = abs(labelNormalise2(iix,L2))>2.2; % 2.2 stdevs empirically..

% there is potential to use iix to find regions which are separate from the
% main cell, and hence might have been incorrectly segmented in 2D
% using this approach, one might be able to remove these regions, which are
% problematic to constrain in z.

% If they can't be removed from the segementation reliably (sub cellular
% spots get picked up a lot), then we can flag them to be replaced by
% smoothed neighbour values for upper and lower.

% Change the approach, so that rather than directly constructing the 3D
% label matrix, we build 2D arrays containing the upper and lower limits
% for each pixel.


% this full-image approach is short in code, but does end up processing
% lots of background pixels along with it - could potentially be speeded up
% by:
% - taking the foreground pixels (L2>0) and squeezing into a 2D image
% - using a moment calculation rather than sorting each column (in
%   imageMaxIndex) to find the max

mx = iix;
mx(L2==0 | dodgy) = NaN;
mx2 = gaussNaNFilt(mx,[3,3],'replicate',[8,8]);
mx(dodgy) = mx2(dodgy);
heightvals = reshape(1:size(gradim,3),[1,1,size(gradim,3)]);

if ~isempty(seedL)
    % need to modify mx to incorporate the height of the seed regions
    % find the maximum height of each seed, set to -Inf everywhere else
    seedHeight = max(bsxfun(@times,seedL>0,heightvals),[],3);
    seedHeight(seedHeight==0) = -Inf;
    
    % reuse mx2 for this
    mx2 = max(mx, seedHeight);
else
    mx2 = mx;
end

if vectgrad
    % if we have directionality to the gradient, the gradient at the upper
    % edge need to be inverted
    % CHECK that this is still the right way round in the new version
    upix = imageMaxIndex(-gradim.*bsxfun(@ge,heightvals,mx2));
else
    % magnitude of the gradient
    upix = imageMaxIndex(gradim.*bsxfun(@ge,heightvals,mx2));
end


if ~isempty(seedL)
    % need to modify mx to incorporate the height of the seed regions
    % find the maximum height of each seed, set to Inf everywhere else
    seedHeight = min(bsxfun(@times,seedL>0,heightvals),[],3);
    seedHeight(seedHeight==0) = Inf;
    
    % reuse mx2 for this
    mx2 = min(mx, seedHeight);
else
    mx2 = mx;
end

lpix = imageMaxIndex(gradim.*bsxfun(@ge,mx2,heightvals));

% have to choose what to do about the dodgy pixels
% for now, NaN them out and fill in with blurring of the upper and lower.

upix(L2==0 | dodgy) = NaN;
lpix(L2==0 | dodgy) = NaN;
nupix = gaussNaNFilt(upix,[2.5,2.5],'replicate',[8,8]);
upix(dodgy) = nupix(dodgy);
nlpix = gaussNaNFilt(lpix,[2.5,2.5],'replicate',[8,8]);
lpix(dodgy) = nlpix(dodgy);

% an additional option is to choose the fate of the dodgy pixels based on
% how far they are from the 2D edge of the cell, with those close to the
% edge more likely to be removed, followed by morphological opening and
% fragmentation check, then application of the upper and lower

if removeDodgy>0 % use the value of this as the threshold normalized distance 0.2 seems good
    B = L2.*double(stdfilt(L2,diamondElement)>0);
    D = bwdist(B>0).*(L2>0);
    nD = labelRangeNormalise(D,L2,0.001);
    
    remove = dodgy & nD<removeDodgy;
    L2(remove) = 0;
    L2 = imopen(L2,diskElement(2.5,1));
end

% smoothing of the upper and lower surfaces to get rid of any
% discontinuities
if smoothScale>0
    
    % the smoothing needs to prevent edges disappearing if possible
    dd = strel('disk',smoothScale,4);
    
    naninds = isnan(lpix);
    lpix(naninds) = numel(heightvals)+2;
    lpix = imopen(lpix,dd);
    lpix(naninds) = 0;
    lpix = imclose(lpix,dd);
    lpix(naninds) = NaN;
    
    naninds = isnan(upix);
    upix(naninds) = numel(heightvals)+2;
    upix = imopen(upix,dd);
    
    upix(naninds) = 0;
    upix = imclose(upix,dd);
    upix(naninds) = NaN;
    
end

% now sort out the 3D label..
% not sure there's a low memory way of doing this
% either repmat or loop over every column of pixels..


L3 = bsxfun(@times,L2,bsxfun(@ge,heightvals,lpix));
L3 = L3.*bsxfun(@ge,upix,heightvals);

% keyboard


% check for fragmentation
%THIS HASN'T BEEN COMPLETED YET
% do in one go
% % [temp,tN] = bwlabeln(L3==ii);
% % if tN>1
% %     % keep only the part with the largest volume
% %     fragstats = regionprops(temp,'Area');
% %     keepind = find([fragstats.Area]==max([fragstats.Area]),1,'first');
% %     L3(L3==ii)=0;
% %     L3(temp==keepind)=ii;
% % %         disp('Sorted out fragmented nucleus') % to see how prevalent this is
% %     % might be better to write to a log instead of the screen
% % end
