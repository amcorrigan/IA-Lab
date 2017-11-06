function str = multiCSVFile(imInfo,customName)

% generate the export file name for the stats structure, from the image
% information structure
%
% This is just the default choice, put here as an attempt to standardize

if nargin<2 || isempty(customName)
    customName = 'Results';
end

% try to separate each set of results into a separate folder

fnames = fieldnames(imInfo);
plateind = find(strcmpi('plate',fnames) | strcmpi('plateID',fnames),1,'first');
wellind = find(strcmpi('well',fnames),1,'first');
fieldind = find(strcmpi('field',fnames) | strcmpi('site',fnames),1,'first');

% for now, assume that they all need to be there, apart from perhaps the
% field
if ~isempty(fieldind)
    str = sprintf('Results/%s/%s_%s_%s_f%d.csv',imInfo.(fnames{plateind}),...
        customName,imInfo.(fnames{plateind}), imInfo.(fnames{wellind}),imInfo.(fnames{fieldind}));
else
    str = sprintf('Results/%s/%s_%s_%s.csv',imInfo.(fnames{plateind}),...
        customName,imInfo.(fnames{plateind}), imInfo.(fnames{wellind}));
end