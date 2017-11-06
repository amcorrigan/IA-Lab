function [poly,cxyz] = sphereVoronoi(tri,xyz)

% might not be very efficient to begin with, just get it working..

x = xyz(:,1);
y = xyz(:,2);
z = xyz(:,3);
cx = mean(x(tri),2);
cy = mean(y(tri),2);
cz = mean(z(tri),2);
cxyz = [cx,cy,cz];

% go through the vertices one at a time
poly = cell(size(xyz,1),1);

for ii = 1:size(xyz,1)
    inds = find(any(tri==ii,2));
    
    if isempty(inds)
        continue;
    end
    tripoints = tri(inds,:);
    
    % poly will consist of the inds elements, but we need to work out the
    % order
    
    poly{ii} = inds(1);
    currpoint = tripoints(1,:);
    tripoints(1,:) = NaN;
    
    currpoint(currpoint==ii) = [];
    
%     while nnz(~isnan(tripoints))
    while ~isempty(currpoint)
        
        nexttri = currpoint(1);

    
        % take out the current vertex, get the next one in the triangle, and
        % find the index of tripoints which also contains that vertex and the
        % current one
        
        % now identify the triangle containing both ii and nexttri
        nextind = find(any(tripoints==nexttri,2));

        poly{ii} = [poly{ii},inds(nextind)];

        currpoint = tripoints(nextind,:);
        currpoint(currpoint==nexttri | currpoint==ii) = [];
% %         nexttri = currpoint(1); % should only be one anyway..
        tripoints(nextind,:) = NaN;

        % continue...
        % fill this in a bit to find the best place to put the loop
    end
    
    
    
end