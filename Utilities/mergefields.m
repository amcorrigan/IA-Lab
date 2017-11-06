function merge = mergefields(old,new,newempty,oldprefix)

% function to merge two structures, overwriting old with new where the
% field exists in both.

% if we specify an oldprefix, put this string at the start of every old
% field before merging.
if nargin<4 || isempty(oldprefix)
    oldprefix = '';
end
if nargin<3 || isempty(newempty)
    newempty = 1; % allow empty new fields to overwrite existing old ones, to preserve previous functionality
end

if isempty(new)
    merge = old;
    return
end
if isempty(old)
    merge = new;
    return
end

if isempty(oldprefix)
    merge = old;
else
    % have to construct the renamed old structure
    oldfnames = fieldnames(old);
    for ii = numel(oldfnames):-1:1
        mfnames{ii} = [oldprefix, oldfnames{ii}];
    end
    
    merge(numel(old)).(mfnames{1}) = []; % so that MATLAB knows how big merge is meant to be when deal is called
    
    for ii = 1:numel(oldfnames)
        [merge.(mfnames{ii})] = deal(old.(oldfnames{ii}));
    end
    % This operation seems to mess up the shape of merge, so change it back
    % here
    merge = reshape(merge,size(old));
end

fnames = fieldnames(new);

for ii = 1:length(fnames)
    for jj = 1:max(numel(old),numel(new))
        if ~isempty(new(jj).(fnames{ii})) || newempty
            merge(jj).(fnames{ii}) = new(jj).(fnames{ii});
        end
    end
end
