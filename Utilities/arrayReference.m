function y = arrayReference(x,inds,nanvalue)

% might be worth implementing some checks here to avoid having to call
% logical in the parent function

wnans = false;
if nnz(isnan(inds))>0
    % make sure we've specified a nanvalue, otherwise throw an error as
    % expected from the old version
    if nargin<3 || isempty(nanvalue)
%         error('inds has NaN values, specify nanvalue as third input')
        % actually, just keeping the NaNs might be good default behaviour
        
        nanvalue = NaN;
    end
    
    % to preserve all the previous functionality, it's probably best to
    % replace the NaNs with an arbitrary value, run as normal, and then
    % replace the values afterwards
    naninds = isnan(inds);
    inds(isnan(inds)) = 1;
    
    wnans = true;
end

if max(inds(:)>1)
    y = x(inds);
else
    y = x(logical(inds));
end

if wnans
    y(naninds) = nanvalue;
end
