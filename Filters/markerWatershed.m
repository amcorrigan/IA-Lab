function L = markerWatershed(gradim,fg,bg,minsize)

% Marker-based watershed segmentation.
% 
% The function takes care of setting the
% background values to zero.
% A potential improvement is to make sure that the labels have the same
% values as the foreground markers, if a non-binary foreground marker array
% was supplied.

if nargin<4
    minsize=0;
end

L = watershed(imimposemin(gradim,fg|bg));

bgvals = unique(L(bg>0));

% % L(multiValueIndices(L,bgvals)) = 0;
% % L = rescaleLabels(L);
% This can be sped up considerably

temp = ones(max(L(:)),1);
temp(bgvals) = 0;
temp2 = [0;cumsum(temp).*temp];
L = temp2(L+1);

L = bwlabel(bwareafilt(L>0,[minsize,Inf]));
