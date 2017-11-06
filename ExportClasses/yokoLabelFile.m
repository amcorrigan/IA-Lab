function str = yokoLabelFile(imInfo)

% generate the export file name for label matrices, from the image
% information structure
%
% This is just the default choice, put here as an attempt to standardize

 str = sprintf('labels/label_w%s_f%d.mat',imInfo.Well,imInfo.Field);
