function pathlist = genpath2cell(pathstr,ignore)

% take the output of genpath and separate it into a cell array of
% individual paths

if nargin<2 || isempty(ignore)
    ignore = '.git';
end

if ispc
    bounds = strfind(pathstr,';');
else
    bounds = strfind(pathstr,':');
end

bounds = [0;bounds(:)];

pathlist = arrayfun(@(x,y)pathstr((x+1):(y-1)),bounds(1:end-1),bounds(2:end),'uni',false);
% who needs loops..


% now have a look at each one and see if it matches the exclusion pattern
keep = cellfun(@isempty,strfind(pathlist,ignore));

pathlist = pathlist(keep);

