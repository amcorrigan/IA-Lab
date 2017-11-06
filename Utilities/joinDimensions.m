function B = joinDimensions(A,dimlist)

% reduce the dimensionality of a multidimensional array by putting the
% listed dimensions together.  Useful for summing more cleanly, or just
% rearranging, etc.

ndim = numel(size(A));

% ought to check for any missing dimensions and put them at the end

if ~iscell(dimlist)
    dimlist = {dimlist};
end

dimlist = cellfun(@(x)x(:)',dimlist,'uni',false);

dimorder = cell2mat(dimlist(:)');

maxdim = max(ndim,max(dimorder));

if numel(dimorder)~=max(dimorder) || ndim>numel(dimorder)
    % need to find the missing dimensions
%     maxdim = max(ndim,max(dimorder));
    needlist = (1:maxdim)';
    
%     present = repmath(needlist,dimorder,'eq');
    present = bsxfun(@eq,needlist,dimorder);
    
    np = sum(present,2);
    
    if any(np>1)
        error('Same dimension specified twice!')
    end
    
    missing = find(np==0)';
    
    dimlist = [dimlist,{missing}];
    dimorder = [dimorder,missing];
    
end

oldsiz = zeros(1,maxdim);
for ii = 1:numel(oldsiz)
    oldsiz(ii) = size(A,ii);
end

newsiz = zeros(1,numel(dimlist));
for ii = 1:numel(newsiz)
    newsiz(ii) = prod(oldsiz(dimlist{ii}));
end

if prod(newsiz)~=prod(oldsiz)
    error('Something''s gone wrong in the dimension assignment')
end

C = permute(A,dimorder);
B = reshape(C,newsiz);


