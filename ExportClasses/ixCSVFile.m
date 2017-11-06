function str = ixCSVFile(imInfo,customname)

% like the yokogawa, the standard export will be the well and field (called
% site for IX)

% This is just the default choice, put here as an attempt to standardize

% not sure if the case of the structure fields is well-controlled, check
% here

if nargin<2 || isempty(customname)
    customname = 'results';
end


fnames = fieldnames(imInfo);
wellfield = find(strcmpi('well',fnames));
sitefield = find(strcmpi('site',fnames));

if ~isempty(wellfield) && ~isempty(sitefield)
    str = sprintf('results/%s%s_f%d.csv',customname,imInfo.(fnames{wellfield}),imInfo.(fnames{sitefield}));
elseif ~isempty(wellfield)
    str = sprintf('results/%s%s.csv',customname,imInfo.(fnames{wellfield}));
elseif ~isempty(sitefield)
    str = sprintf('results/%s_f%d.csv',customname,imInfo.(fnames{sitefield}));
else
    str = sprintf('results/%s.csv',customname);
end