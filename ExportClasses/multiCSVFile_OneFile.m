function str = multiCSVFile_OneFile(imInfo,customName)

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


    str = sprintf('Results/%s_%s.csv',customName, imInfo.(fnames{plateind}));
end