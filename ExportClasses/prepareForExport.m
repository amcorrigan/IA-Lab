function stats2 = prepareForExport(stats,include,exclude)

% prepare the statistics structure for export
% 
% To export to a csv-type file, each of the fields should contain only
% scalars
% So go through the fields, and if there are non-scalars, replace the field
% with multiple fields, one for each element

fnames = fieldnames(stats);

if nargin<3
    if nargin==2 && isstruct(include)
        inames = fieldnames(include);
        
        ind = find(strcmpi('exclude',inames),1,'first');
        if ~isempty(ind)
            exclude = include.(inames{ind});
        else
            exclude = false(numel(fnames),1);
        end
        
        ind = find(strcmpi('include',inames),1,'first');
        if ~isempty(ind)
            include = include.(inames{ind});
        else
            include = true(numel(fnames),1);
        end
    else
        exclude = false(numel(fnames),1);
    end
end

if nargin<2 || isempty(include)
    include = true(numel(fnames),1);
end

if iscell(exclude)
    exclude = cellfun(@(x)any(strcmpi(x,exclude)),fnames);
end

if iscell(include)
    % cell array of field names supplied
%     fstr = include;
    include = cellfun(@(x)any(strcmpi(x,include)),fnames);
end

maxSize = zeros(numel(fnames),1);
% skip = false(numel(fnames),1);
skip = exclude(:) | ~include(:);

for ii = 1:numel(fnames)
    
    fieldsize = arrayfun(@(x)numel(x.(fnames{ii})),stats);
    
    maxSize(ii) = max(fieldsize);
    maxInd = find(fieldsize==maxSize(ii),1,'first');
    if iscell(stats(maxInd).(fnames{ii}))
        % for a cell array, check that it's strings inside
        if ~ischar(stats(maxInd).(fnames{ii}){1})
            skip(ii) = true;
        end
    elseif ischar(stats(maxInd).(fnames{ii}))
        maxSize(ii) = 1; % strings of any length can be accommodated
    end
end

trivial = maxSize<=1 & ~skip;
nonTrivial = maxSize>1 & ~skip;

for ii = 1:numel(fnames)
    if trivial(ii)
        % this syntax is awful!
        [stats2(1:numel(stats),1).(fnames{ii})] = stats.(fnames{ii});
    elseif nonTrivial(ii)
        fmt = ['%s_%0.', num2str(ceil(log10(maxSize(ii)))), 'd'];
        for jj = 1:maxSize(ii)
            newname = sprintf(fmt,fnames{ii},jj);
            
            tempval = arrayfun(@(x)subarrayfcn(x,fnames{ii},jj),stats,'uni',false);
            
            [stats2(1:numel(stats),1).(newname)] = tempval{:};
        end
    end
end

if ~exist('stats2','var')
    stats2 = struct;
end

end

function val = subarrayfcn(x,fname,ind)

% this function is used by arrayfun above to extract the ind'th element of
% the field fname of the structure x, or NaN if that element doesn't exist
%
% ie
% x.(fname)(ind)

if numel(x.(fname))<ind
    val = NaN;
else
    val = x.(fname)(ind);
end

end
