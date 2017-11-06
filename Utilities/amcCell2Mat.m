function M = amcCell2Mat(C,padval,dim)

% convert a cell array containing oddly sized arrays into a numerical
% array, padded to the right size (usually with NaNs)
%
% Unlike cell2mat, this will automatically concatenate along the first
% singleton dimension if not specified.  Also, the cell array is linearized
% first, rather than preserving the dimensions

% A better way to do this is to concatenate into the first singleton
% dimension of the cell array..

if nargin<2 || isempty(padval)
    padval = NaN;
end

if nargin<3 || isempty(dim)
    siz = [];
    for ii = 1:numel(C)
        temp = size(C{ii});
        siz((numel(siz)+1):numel(temp)) = 1;
        
        siz(1:numel(temp)) = max(siz(1:numel(temp)),temp);
    end
    
    dim = find(siz==1,1,'first');
    if isempty(dim)
        dim = numel(siz)+1;
    end
end

inds = cellfun(@isstruct,C);
testind = find(cellfun(@isstruct,C),1,'first');
if ~isempty(testind) & ~isstruct(padval)
    % if we want to concatenate structure, then all the fields need to be
    % the same.  Therefore, any non-struct elements of the cell array need
    % replacing with scalar structs, populated with the padval value
    fnames = fieldnames(C{testind});
    vals = num2cell(padval*ones(1,numel(fnames)));
    args = [fnames(:)';vals(:)'];
    scalstruct = struct(args{:});
    
    C(~inds) = repmat({scalstruct},[nnz(~inds),1]);
    padval = scalstruct;
end

% now ready to do the concatenation
M = amcCat(dim,padval,C{:});