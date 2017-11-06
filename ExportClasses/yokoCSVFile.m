function str = yokoCSVFile(imInfo,customName)

% generate the export file name for the stats structure, from the image
% information structure
%
% This is just the default choice, put here as an attempt to standardize

if nargin<2 || isempty(customName)
    customName = 'results';
end

 str = sprintf('results/%s%s_f%d.csv',customName,imInfo.Well,imInfo.Field);