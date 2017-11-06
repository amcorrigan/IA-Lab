classdef CentroidIntensityAZMeasure < AZMeasure
    % take the intensity at the centroid of the segmented regions
    
    properties
        Neighbourhood = [1]; % by default, take only a single pixel
        
    end
    methods
        function this = CentroidIntensityAZMeasure(propPrefix,nhood)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(nhood)
                this.Neighbourhood = nhood;
            end
        end
        
        function [stats,varargout] = measure(this,L,imdata)
            if iscell(L)
                L = L{1};
            end
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            % at some point, allow coordinates to be directly supplied; for
            % now, just take the pixel nearest the centroid of the region
            % For this purpose, it doesn't matter if the centroid isn't
            % part of the original region, but in some cases it might, in
            % which case the PixelList value closest to the centroid should
            % be chosen to maintain generality.
            
            numobj = max(L(:));
            prestats = regionprops(L,'Centroid');
            
            % get the rounded centroid for each region
            rxyz = round(cell2mat({prestats.Centroid}'));
            
            % swap x and y back
            rxyz(:,1:2) = rxyz(:,[2,1]);
            
            imsiz = size(L);
            
            % convert to linear indices
            lininds = amcSub2Ind(imsiz,rxyz);
            
            pointL = zeros(size(L));
            pointL(lininds) = (1:numobj)';
            pointL = imdilate(pointL,this.Neighbourhood);
            
            for ii = 1:numel(imdata)
                
                tempstats = regionprops(pointL,imdata{ii},'MeanIntensity');
                
                outputname = [this.Prefix,'CentroidIntensity',num2str(ii)];
                
                [stats(1:numel(tempstats),1).(outputname)] = tempstats.MeanIntensity;
                
            end
            
        end
    end
end
