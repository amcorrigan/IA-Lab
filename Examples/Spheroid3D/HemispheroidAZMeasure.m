classdef HemispheroidAZMeasure < AZMeasurePixels
    
    % estimation of the spheroid volume, by looking for a hemisphere along
    % the z-direction and doubling the volume
    
    properties
%         PixelSize = [1,1,1]; % now stored in superclass
        
        PeakRangeFraction = [0.01,0.05];
    end
    methods
        function this = HemispheroidAZMeasure(propPrefix,pixsize)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            if nargin<2
                pixsize = [];
            end
            this@AZMeasurePixels(propPrefix,pixsize);
            
            % would be much easier to do varargin...
        end
        
        function [stats,varargout] = measure(this,L,~)
            if iscell(L)
                L = L{1};
            end
            
            
            pixsize = this.PixelSize;
            if numel(pixsize)==1
                pixsize = [pixsize, pixsize, 1];
            elseif numel(pixsize)==2
                pixsize = [pixsize, 1];
            end
            
            voxvol = prod(pixsize(1:3));
            axy = pixsize(1)*pixsize(2);
            axz = pixsize(1)*pixsize(2);
            ayz = pixsize(2)*pixsize(3);
            
            stats = struct([]);
            
            for jj = 1:max(L(:))
                bw = L==jj;
                
                zarea = squeeze(sum(sum(bw,1),2));
                cumuvol = cumsum(zarea);

                % looking for the maximal value, then double the cumulative sum
                % at that point
                
                % two options for each z-level
                % - that slice is the single widest point, and so shouldn't
                %   be included in the doubling
                % - that widest point is above the slice, so the slice
                %   should be included in the doubling.
                stats(jj).Volume = 2*voxvol*mean(cumuvol(zarea==max(zarea)));
                
                try
                for ii = 1:numel(this.PeakRangeFraction)
                    inds = find(zarea>=((1-this.PeakRangeFraction(ii))*max(zarea)));
                    inds(inds==1) = 2;
                    
                    volvals = [2*cumuvol(inds); 2*cumuvol(inds-1)+zarea(inds)];
                    
                    stats(jj).(sprintf('MeanVol%d',ii)) = voxvol*mean(volvals);
                    stats(jj).(sprintf('ErrorVol%d',ii)) = voxvol*std(volvals)/sqrt(numel(volvals));
                end

                catch ME
                    rethrow(ME)
                end
                stats(jj).Projected2DArea = axy*max(zarea);

                % also want to estimate the surface area
                % need to be careful not to include the part that is going to
                % be doubled up.
                
                % use the first estimate of uncertainty level to come up with
                % several surface area estimates
                inds = find(zarea>=((1-this.PeakRangeFraction(1))*max(zarea)));
                
                areaestimates = [];
                
                for ii = 1:numel(inds)
                    d1 = abs(diff(bw(:,:,1:inds(ii)),1));
                    d2 = abs(diff(bw(:,:,1:inds(ii)),2));
                    % slicing the array zt the midpoint should stop the
                    % upper surface being included in the calculation
                    d3 = abs(diff(bw(:,:,1:inds(ii)),3)); 
                    
                    % also need to calculate the two estimates depending on
                    % whether the chosen slice is included in the doubling
                    % or not.
                    
                    upperestimate = 2*(nnz(d3)*axy + nnz(d1)*ayz + nnz(d2)*axz);
                    lowerestimate = upperestimate - (nnz(d3(:,:,end))*axy + ...
                        nnz(d1(:,:,end))*ayz + nnz(d2(:,:,end))*axz);
                    
                    areaestimates = [areaestimates;...
                        upperestimate; lowerestimate];
                end
                
                stats(jj).SurfaceArea = mean(areaestimates);
                stats(jj).SurfaceAreaError = std(areaestimates)./sqrt(numel(inds));
                
                stats(jj).ZProfile = zarea;
                
                if ~isempty(this.Prefix)
                    stats = prefixFields(stats,this.Prefix);
                end
            end
        end
        
        
    end
end
