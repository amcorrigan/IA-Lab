classdef DelaunayEntropyAZMeasure < AZMeasure
    % Measure cell organisation using the entropy of Delaunay triangle areas.
    %
    % Works best for standardisation if NumBins is supplied as a vector of
    % bin centres rather than a scalar indicating number
    properties
        NumBins = 5;
    end
    methods
        function this = DelaunayEntropyAZMeasure(propPrefix,nbins)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            
            this@AZMeasure(propPrefix);
            
            if nargin>0 && ~isempty(nbins)
                this.NumBins = nbins;
            end
            
            this.OutputType = 'field';
        end
        
        function [stats,varargout] = measure(this,labdata,~)
            if iscell(labdata)
                labdata = labdata{1};
            end
            
            if size(labdata,2)<=3
                % assume that it's coordinates
                xy = labdata;
            else
                % get the coordinates as the centroid of the region
                temp = regionprops(labdata,'Centroid');
                xy = cell2mat({temp.Centroid}');
                xy(:,[1,2]) = xy(:,[2,1]);
            end
            
            tri = delaunayn(xy);
            while size(tri,2)>3
                % check that this does what I think it does..
                tri = this.getfacets(tri);
            end
            
            % want to remove the convex hull, or in fact any triangles
            % which have a vertex which is a member of the convex hull
            convedges = convhulln(xy);
            while size(convedges,2)>2
                convedges = this.getfacets(convedges);
            end
            
            convvertex = unique(convedges(:));
            remtri = any(arrayfun(@(x)any(convvertex==x),tri),2);
            tri = tri(~remtri,:);
            
            A = this.triareas(tri,xy);
            
            [f,x] = hist(A,this.NumBins);
            p = f/sum(f);
            deltax = x(2)-x(1);
            
            % now do the entropy calculation
            stats.TriEntropy = sum(-deltax*p(p>0).*log(p(p>0)));
            
            % is this enough? or do we also need a length cutoff?
            
            if ~isempty(this.Prefix)
                stats = prefixFields(stats,this.Prefix);
            end
            
            if nargout>1
                for ii = (nargout-1):-1:1
                    varargout{ii} = [];
                end
            end
        end
    end
    
    methods (Static)
        function [C,tripair] = getfacets(tri)

            % returns a list of the facets and which simplices are on either side
            
            nfacets = size(tri,2);
            facetlist = zeros(nfacets*size(tri,1),nfacets-1);

            for ii = 1:nfacets;
                indlist = 1:nfacets;
                indlist(ii) = [];
                facetlist(ii:nfacets:end,:) = tri(:,indlist);
            end

            hf = sort(facetlist,2);

            [C,ia,ic] = unique(hf,'rows');

            if nargout>1
                tripair = zeros(size(C,1),2);

                for ii = 1:size(C,1)
                    % find which facetlist elements these have come from, and record the
                    % triangle numbers
                    thisedge = find(ic==ii);
                    tripair(ii,1:numel(thisedge)) = ceil(thisedge(:)'/nfacets);
                end
            end
        end
        
        function [A,perim,longl] = triareas(tri,xy)

            % only works for 2D at the moment, but should be able to replace the cross
            % product calculation to fix this.
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
        end
    end
end
