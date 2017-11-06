function useinds = multiValueIndices(indarray,indvals)

% like logical indexing, but for multiple index values
% 
% eg V(L==1 || L==2 || L==3 || etc..)
% use a loop to avoid potential memory problems with repmat
% 
% Example:
% 
useinds = false(size(indarray));

for ii = 1:numel(indvals)
    useinds = useinds | (indarray==indvals(ii));
end
