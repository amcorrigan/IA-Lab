function Sout = prefixFields(Sin,prefix,skipIdx)

% go through each of the fields and prefix the name with the chosen string
if nargin<3 || isempty(skipIdx)
    skipIdx = [];
end

fnames = fieldnames(Sin);

if ischar(prefix)
    prefix = repmat({prefix},[numel(fnames),1]);
end

prefix(skipIdx) = {''};

for ii = 1:numel(fnames)
    [Sout(1:numel(Sin)).([prefix{ii}, fnames{ii}])] = Sin.(fnames{ii});
end

Sout = reshape(Sout,size(Sin));