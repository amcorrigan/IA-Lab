function str = ixQCFile(imInfo,customname)

% like the yokogawa, the standard export will be the well and field (called
% site for IX)

% This is just the default choice, put here as an attempt to standardize

% not sure if the case of the structure fields is well-controlled, check
% here

if nargin<2 || isempty(customname)
    customname = 'QCImage';
end


fnames = fieldnames(imInfo);
wellfield = find(strcmpi('well',fnames));
sitefield = find(strcmpi('site',fnames));

if ~isempty(wellfield) && ~isempty(sitefield)
    str = sprintf('QCImages/%s_%s_f%d.png',customname,imInfo.(fnames{wellfield}),imInfo.(fnames{sitefield}));
elseif ~isempty(wellfield)
    str = sprintf('QCImages/%s_%s.png',customname,imInfo.(fnames{wellfield}));
elseif ~isempty(sitefield)
    str = sprintf('QCImages/%s_f%d.png',customname,imInfo.(fnames{sitefield}));
else
    str = sprintf('QCImages/%s.png',customname);
end