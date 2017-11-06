function Lout = rescaleLabels(Lin)

% rescale the label array so that there are no gaps in the numbers, useful
% for if you've merged non touching objects after using bwlabel, or if some
% objects have been removed using regionprops criteria.

% % lvals = unique(Lin(Lin>0));

% % Lout = zeros(size(Lin));
% % 
% % for ii = 1:numel(lvals)
% %     Lout(Lin==lvals(ii)) = ii;
% % end

lvals = unique(Lin(Lin>0));
% need to invert this

if nnz(lvals~=0)==0
    Lout = Lin;
    return;
end
ix = zeros(max(lvals)+1,1);
ix(lvals+1) = 1:numel(lvals);
Lout = ix(Lin+1);

