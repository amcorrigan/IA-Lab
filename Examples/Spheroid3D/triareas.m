function [A,perim,longl] = triareas(tri,xy)

% only works for 2D at the moment, but should be able to replace the cross
% product calculation to fix this.

if nargin<2 || isempty(xy)
	fnames = fieldnames(struct(tri));
	if any(strcmpi(fnames,'triangulation'))
    		%tri should be an object rather than the vertex indices
    		% do something about that!
    		% the things we need are stored in the fields of the triangulation
    		% object
    		xy = tri.X;
    		tri = tri.Triangulation;
	elseif any(strcmpi(fnames,'vertices'))

		% or it could be a fv structure
		xy = tri.vertices;
		tri = tri.faces;
	end
end

A = zeros(size(tri,1),1);
perim = zeros(size(tri,1),1);
longl = zeros(size(tri,1),1);

for ii = 1:size(tri,1)
    ab = xy(tri(ii,2),:) - xy(tri(ii,1),:);
    ac = xy(tri(ii,3),:) - xy(tri(ii,1),:);
    bc = xy(tri(ii,3),:) - xy(tri(ii,2),:);
    
    % cross product
    A(ii) = 0.5*abs(ab(1)*ac(2) - ab(2)*ac(1));
    lens = sqrt(sum([ab;bc;-ac].^2,2));
    
    perim(ii) = sum(lens);
    longl(ii) = max(lens);
    
end