function Lout = convexHullLabel(L,showProgress)

% go through each slice of the label array and calculate the convex hull of
% each object in it.

if nargin<2 || isempty(showProgress)
    showProgress = false;
end


% have to go through each label in each slice

Lout = zeros(size(L));

numObj = max(L(:));

fig = figure('visible','off');
% open a new current figure to catch all the output from sfm_local_chanvese

for jj = 1:numObj
    tempbw = L==jj;
    outbw = false(size(tempbw));
    
    for ii = 1:size(L,3)
        bwslice = tempbw(:,:,ii);
        
        if nnz(bwslice)>0
            % calculate the convex hull of all the pixels which have this
            % label in this slice
            outslice = bwconvhull(bwslice);
            
            % some smoothing and/or active contour could be applied here to
            % get back tight to the edge of the spheroid
            % how slow would the active contour be for every slice/label??
            % turns out, not that slow!
            
%             seg = sfm_local_chanvese(bwslice,outslice,120,0.05,20);
            seg = sfm_local_chanvese(bwslice,outslice,400,0.01,20,showProgress);
            
            
%             outbw(:,:,ii) = outslice;
            outbw(:,:,ii) = seg;
            
        end
    end
    
    % before applying to the label array, we can do some morphological
    % smoothing to reduce the jitter between slices
    % want to make sure that the edges can't play a role
    
    outbw = imclose(padarray(outbw,[0,0,2],false,'both'),ones(1,1,5));
    outbw = outbw(:,:,3:end-2);
    
    % the other thing to try would be to then go through the label in
    % another dimension (eg x rather than z) to try to tidy up the slices
    % would this be too slow?
    
    
    Lout(outbw) = jj;
    
    if showProgress
        fprintf('Progress %d percent\n',round(jj/numObj * 100));
    end
    
end

close(fig)

