function outFile = yokoQCFile(imInfo,prefix)

% the prefix is an additional argument that will allow multiple QCimages to
% be exported per field (ie that wouldn't be distinguished by imInfo), eg
% 'nuc','cyto','spots', etc

if nargin<2 || isempty(prefix)
    prefix = '';
end

str = sprintf('QC/%sQC_%s_f%d.png',prefix,imInfo.Well,imInfo.Field);
