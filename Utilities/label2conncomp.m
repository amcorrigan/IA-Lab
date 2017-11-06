function CC = label2conncomp(L,conn)

% Convert the label matrix to the connected component structure, preserving
% the order of the values
%
% the conn value doesn't actually do anything, but it is expected to be in
% the connected component structure


% bwconncomp will just relabel everything, so use regionprops to get what
% we need

CC.ImageSize = size(L);

if nargin<2 || isempty(conn)
    ndim = numel(CC.ImageSize);
    conn = (3.^ndim) - 1;
end

CC.Connectivity = conn;
CC.NumObjects = max(L(:)); % this might not be strictly true, but we're keeping the values of the indices

stats = regionprops(L,'PixelIdxList');

CC.PixelIdxList = {stats.PixelIdxList}';




