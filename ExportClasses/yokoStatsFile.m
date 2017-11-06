function str = yokoStatsFile(imInfo,customName)

% generate the export file name for the stats structure, from the image
% information structure
%
% This is just the default choice, put here as an attempt to standardize

if nargin<2 || isempty(customName)
    customName = 'stats';
end

 str = sprintf('stats/%s%s_f%d.mat',customName,imInfo.Well,imInfo.Field);