function A = amcPolyArea(poly,xyz,cc)

% calculate the polygon area by breaking down into triangles and summing

if nargin<3 || isempty(cc)
    cc = cell2mat(cellfun(@(inds)mean(xyz(inds,:),1),poly,'uni',false));
end

A = zeros(numel(poly),1);

for ii = 1:numel(poly)
    if isempty(poly{ii})
        continue;
    end
    
    vertxyz = xyz(poly{ii},:);
    
% %     dx = [vertxyz(:,1),vertxyz([2:end,1],1)] - cc(ones(size(vertxyz,1),1),1)*[1,1];
% %     dy = [vertxyz(:,2),vertxyz([2:end,1],2)] - cc(ones(size(vertxyz,1),1),2)*[1,1];
% %     dz = [vertxyz(:,3),vertxyz([2:end,1],3)] - cc(ones(size(vertxyz,1),1),3)*[1,1];
    
    dxyz = bsxfun(@minus,vertxyz,cc(ii,:));
    A(ii) = 0.5*sum(sqrt(sum(cross(dxyz,dxyz([2:end,1],:)).^2,2)));
end

