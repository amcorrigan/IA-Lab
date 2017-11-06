function T = addMissingFields(S,fnames,val)

% add fields to the structure S where they don't already exist.

if nargin<3 || isempty(val)
    val = [];
end

% not necessary in MATLAB function syntax
T = S;

snames = fieldnames(S);
for ii = 1:numel(fnames)
    if ~sum(strcmp(fnames{ii},snames))
        % add the field
% %         [T.(fnames{ii})] = repmat({val},[numel(T),1]);
        [T.(fnames{ii})] = val;
    end
end