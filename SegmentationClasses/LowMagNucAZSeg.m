%  Segmentation of small and clustered nuclei
%> @file LowMagNucAZSeg.m
%> @brief Segmentation of small and clustered nuclei
%> @brief Tuneable parameters are the approximate radius of nuclei, the threshold, and the weight of smoothing
%> Detect nuclei using histogram equalisation and thresholding, separate touching nuclei using marker-based watershed
classdef LowMagNucAZSeg < TwoStageAZSeg
    % Another attempt at a simple DAPI segmentation of small and clustered
    % nuclei
    
    % For this one the procedure is:
    % - adaptive histogram equalisation - this part needs tuning to make
    %   sure that the cytoplasm doesn't get blown up too much
    % - background subtraction - subtracting off a fraction of a dilated
    %   and blurred version
    % - local maxima by step transform and smoothing (want to implement the
    %   gradient flow approach for this soon)
    % - threshold to find nuclei
    % - distance transform for basins
    % - add extra foreground markers at smoothed minima of the basins,
    %   excluding regions near existing local maxima
    % - Watershed, filling in most of the background to save time and
    %   resetting the boundaries using the thresholded mask
    
    properties
		%> Radius of nuclei
        NucRadius
		%> Threshold applied to histogram-equalised image
        Thresh
		%> Weighting given to background subtraction
        SmoothWeight
    end
    methods
        function this = LowMagNucAZSeg(nucrad,thr,smoothweight)
            this = this@TwoStageAZSeg(...
                {'NucRadius','SmoothWeight','Thresh'},...
                {'Nucleus detection','Smoothing weight','Threshold'},...
                [1,1,1.5],'Small nucleus detection',1,0,1);
            
            
            if nargin>0 && ~isempty(nucrad)
                this.NucRadius = nucrad;
            end
            if nargin>1 && ~isempty(thr)
                this.Thresh = thr;
            end
            if nargin>2 && ~isempty(smoothweight)
                this.SmoothWeight = smoothweight;
            end
            
            
            
        end
        
        function fim = runStep1(this,im,~)
            
            if iscell(im)
                im = im{1};
            end
            
            
            nim = rangeNormalise(im);
            J = adapthisteq(nim,'numtiles',[16,16],'cliplimit',0.05);
            
            
            
            bgim = gaussFiltND(imdilate(J,diskElement(this.NucRadius)),this.NucRadius*[1,1]);
            
            Jsub = gaussFiltND(J,[1,1]) - this.SmoothWeight*bgim;
            
            S = steptrans(Jsub,diskElement(2.5,1),12);
            
            smoothSize = this.NucRadius/5 * [1,1];
            
            lmax0 = imregionalmax(gaussFiltND(S,smoothSize));
            
            % merge maxima that are too close together
            % this is depressingly slow..
%             lmax = bwmorph(imfill(imdilate(lmax0,diskElement(this.NucRadius/3)),'holes'),'shrink',Inf);
            % try centroid calculation instead
            stats = regionprops(imdilate(lmax0,diskElement(this.NucRadius/3)),'Centroid');
            temp = {stats.Centroid}';
            
            yx = cat(1,temp{:});
            lininds = amcSub2Ind(size(lmax0),round(yx(:,[2,1])));
            lmax = false(size(lmax0));
            lmax(lininds) = true;
            
            fim = {Jsub,lmax};
        end
        
        function L = runStep2(this,~,fim,~,~)
            bw2 = fim{1};
            % tidy up bw as this is the final shape of the nuclei
%             bw2 = imfill(gaussFiltND(bw,[1.5,1.5])>0.5,'holes');
            
            lmax = fim{2};
            
            lmax = lmax & bw2; % only keep maxima above the threshold
            
            
            Dbasin = -bwdist(~bw2); % basins for separating nuclei
            
            Ddist = bwdist(lmax);
            Ddist(~bw2) = max(Ddist(bw2));
            
            
            temp = imerode(~bw2,true(5));
            bg = imerode(temp,true(3));
            
            
            extramax = imregionalmin(gaussFiltND(Dbasin,[2,2]));
            
            extramax = extramax & ~imdilate(lmax,diskElement(0.75*this.NucRadius));
            
            % extramax will form part of the bg
            
            Dbasin = Dbasin + 0.5*Ddist;
            Dbasin(temp & ~bg) = 1+max(Dbasin(:)); %set the height around the bg so that all the foreground is filled first
            % the background is essentially used here to speed up the
            % watershed (preassigning most of the pixels), the delineation
            % between foreground and background has already been decided.
            
            L = markerWatershed(Dbasin,lmax,bg|extramax);
            L(bw2==0) = 0;
        end
        
    end
end
