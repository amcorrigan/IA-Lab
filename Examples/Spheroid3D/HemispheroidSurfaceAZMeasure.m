classdef HemispheroidSurfaceAZMeasure < AZMeasurePixels
    
    % experimental measurements of spheroid properties
    %
    % Estimate the surface area from a isosurface rendering, and then find
    % the individual nuclei that are close to the surface.  This allows an
    % estimate of average cell size, and potentially allows heterogeneity
    % measures at some point.
    
    properties
        SurfaceDepth = 30;
    end
    methods
        function this = HemispheroidSurfaceAZMeasure(propPrefix,pixsize)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            if nargin<2
                pixsize = [];
            end
            this@AZMeasurePixels(propPrefix,pixsize);
            
        end
        
        function [stats,varargout] = measure(this,L,~)
            
            % for now assume that there is only one spheroid in the field
            % of view
            
            zarea = squeeze(sum(sum(L{1}>0,1),2));
            
            
            if nnz(zarea)==0
                stats = [];
                return
            end
            nxyz = L{2};
            
            D = bwdistsc(L{1}==0,this.PixelSize);
            
            invals = interp3(L{1}>0,nxyz(:,2),nxyz(:,1),nxyz(:,3),'nearest');
            maxind = find(zarea==max(zarea(:)));
            try
            sxyz = nxyz(nxyz(:,3)<=max(maxind) & invals==1,:);
            catch ME
                rethrow(ME)
            end
            dvals = interp3(D,sxyz(:,2),sxyz(:,1),sxyz(:,3));
            
            fv = surfaceRendering(L{1}(:,:,1:maxind),this.PixelSize,0.25,true);
            
            stats.IsosurfaceArea = sum(triareas(fv.faces,fv.vertices));
            stats.TotalNuclei = size(sxyz,1);
            stats.SurfaceNuclei = nnz(dvals<=this.SurfaceDepth);
            
            stats.SurfacePerNucleus = stats.IsosurfaceArea/stats.SurfaceNuclei;
            
            % also add in the more experimental measurements, trying to
            % estimate the amount of surface that belongs to each nucleus
            
            kxyz = sxyz(dvals<this.SurfaceDepth & dvals>=0,:);
            
            if size(kxyz,1)<4
                stats.IndividualAreasMean = NaN;
                stats.IndividualAreasStd = NaN;
                stats.IndividualAreasTrimMean = NaN;
                return
            end
            
            % in order to generate the triangulation, the units need to be
            % correct
            scxyz = bsxfun(@times,kxyz,this.PixelSize.*[1,1,-1]);
            
            % then for the convex hull, project all the points onto the
            % surface of a sphere
            shxyz = bsxfun(@minus,scxyz,[mean(scxyz(:,1:2),1),min(scxyz(:,3))]);
            nxyz = bsxfun(@rdivide,shxyz,sqrt(sum(shxyz.^2,2)));
            
            try
            tri = convhulln(nxyz);
            [a,p,l] = triareas(tri,scxyz);
            catch ME
                if strcmpi(ME.identifier,'MATLAB:qhullmx:DegenerateData')
                    stats.IndividualAreasMean = NaN;
                    stats.IndividualAreasStd = NaN;
                    stats.IndividualAreasTrimMean = NaN;
                    return
                else
                    rethrow(ME)
                end
            end
            
            try
            [poly,cxyz] = sphereVoronoi(tri,scxyz);
            A = amcPolyArea(poly,cxyz);
            catch ME
                rethrow(ME)
            end
            % A now contains estimates of the amount of surface area per
            % nucleus.
            % This needs looking at to remove any dodgy points on the
            % bottom
            
            % try recording a whole bunch of measures to begin with
            % - the overall area per nucleus
            % - remove all polygons in the lowest layer
            % - remove the lowest layer and oddly oriented normals, and
            % calculate a robust trimmed mean
            nn = polyNormal(poly,cxyz);
            
            
            maxz = max(kxyz(:,3));
            minz = min(kxyz(:,3));
            
            % remove the bottom layer from the area estimates
            dodgyInds = kxyz(:,3)==maxz;
            
            % also remove anything that is near the bottom and has a normal
            % that is close to vertical
            dodgyInds = dodgyInds | (kxyz(:,3)>(0.75*maxz + 0.25*minz) & ...
                abs(nn(:,3))>0.75);
            
            stats.IndividualAreasMean = mean(A(~dodgyInds));
            stats.IndividualAreasStd = std(A(~dodgyInds));
            stats.IndividualAreasTrimMean = trimmean(A(~dodgyInds),10);
            
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
end