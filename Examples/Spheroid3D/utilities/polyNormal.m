function nn = polyNormal(poly,xyz,reps)

% try to measure the approximate normal to the polygons
% This is approximate because the polygon doesn't have to lie flat, so
% there isn't really a unique normal vector
% So instead, randomly sample triangles between the vertices and calculate the
% Kuramoto average of their unit vector cross products

if nargin<3 || isempty(reps)
    reps = 10;
end

nn = NaN*zeros(numel(poly),3);

for ii = 1:numel(poly)
    if isempty(poly{ii})
        continue;
    end
    pinds = cell2mat(arrayfun(@(x)randperm(numel(poly{ii}),3),(1:reps)','uni',false));
    
    pinds = sort(pinds,2);
    
    rinds = poly{ii}(pinds);
    
    nvals = cross(xyz(rinds(:,3),:)-xyz(rinds(:,1),:),xyz(rinds(:,2),:)-xyz(rinds(:,1),:),2);
    
    % normalise
    nvals = bsxfun(@rdivide,nvals,sqrt(sum(nvals.^2,2)));
    
    % average
    temp = sum(nvals,1);
    nn(ii,:) = temp./sqrt(sum(temp.^2,2));
end

