function outpath = findChildFolders(inpath)

% % % find all folders inside the current folder, which are 'leaf' folders (ie
% % % they don't contain any others)
% % 
% % paths = recursiveFolders(inpath);
% % 
% % end
% % 
% % 
% % function outpath = recursiveFolders(inpath)

% find folders inside
% use dir for now, can switch if it's too slow
listing = dir(inpath);
listing(~[listing.isdir]) = [];
% also need to remove the dots
% are they always 1 and 2?
listing(1:2) = [];

if ~isempty(listing)
    outpath = {};
    for ii = 1:numel(listing)
        outpath = [outpath;findChildFolders(fullfile(inpath,listing(ii).name))];
    end
else
    outpath = {inpath};
end

end