function s = amcFullDir(str,isadir,fol)

% like dir, but also includes the full path to the file as one of the
% fields, and gets rid of any '.' or '..' 

if nargin<3 || isempty(fol)
    fol = cd;
end
if nargin<2
    isadir = [];
end

if nargin<1 || isempty(str)
    str = '*';
end

origfol = cd;

cd(fol)

s = dir(str);

remove = false(size(s));

for ii = 1:numel(s)
    if strcmpi(s(ii).name,'.') || strcmpi(s(ii).name,'..')
        remove(ii) = true;
    end
    if ~isempty(isadir) && s(ii).isdir~=isadir
        remove(ii) = true;
    end
end

s(remove) = [];

% now add a full path field to each element
for ii = 1:numel(s)
    s(ii).fullpath = fullfile(cd,s(ii).name);
end

if isempty(s)
    % if no files have been found, we need to add the fullpath field to the
    % empty structure
    s = struct('name', {}, 'date', {}, 'bytes', {}, 'isdir', {}, 'datenum', {}, 'fullpath', {});
end

cd(origfol)