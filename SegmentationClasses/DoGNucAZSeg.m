% Segmentation of nuclei based on gradient of intensity at edges
%> @file DoGNucAZSeg.m
%> @brief Segmentation of nuclei based on gradient of intensity at edges
% ======================================================================
%> @brief Tuneable parameters are the typical size of nuclei and the detection threshold
%
%> Algorithm details - Difference-of-Gaussians to detect foreground markers, followed 
%> by marker-based gradient watershed segmentation.
%> 
%> The class inherits from TwoStageAZSeg, which allows the detection threshold to be
%> interactively tuned in the middle of the process, without rerunning the entire algorithm
%> from the start.
%> TwoStageAZSeg does this by splitting the segmentation into two steps, with the threshold
%> being applied between the two steps.
% ======================================================================
classdef DoGNucAZSeg < TwoStageAZSeg %AZSeg
    % Difference of Gaussians to find centres, gradient watershed for
    % segmentation
    properties
		%> Typical size (diameter) of nuclei, used in the initial filtering
        NucSize = 12;
		%> Threshold applied to the filtered image to pick out centres of nuclei
        Threshold = 0.1;
    end
    methods
		% ======================================================================
		%> @brief Class constructor
		%>
		%> Return the segmentation object with initial values for tuneable parameters
		%>
		%> @param nucsiz The rough diameter of nuclei in the images
		%> @param thresh The threshold of detection in the DoG-filtered image
		%>
		%> @return this instance of the DoGNucAZSeg class.
		% ======================================================================
        function this = DoGNucAZSeg(nucsiz,thresh)
            % set up the interactive parameter tuning
            this = this@TwoStageAZSeg({'NucSize','Threshold'},...
                {'Nucleus Size','Threshold Adjustment'},[1,1.5],...
                'Nucleus Detection',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(nucsiz)
                this.NucSize = nucsiz;
            end
            if nargin>1 && ~isempty(thresh)
                this.Threshold = thresh;
            end
            
        end
        
		% ======================================================================
		%> @brief Run the first part of the two-stage segmentation (local maxima finding)
		%>
		%> 
		%> @param this instance of the DoGNucAZSeg class
		%> @param im image data on which to perform segmentation
		%> @param ~ no label data required for this class
		%>
		%> @return outim cell array of filtered image data - the first element is thresholded before passing to runStep2
		% ======================================================================
        function outim = runStep1(this,im,~)
            % this kind of input checking can be farmed out to specialized
            % superclasses
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            numtiles = ceil(size(im)/(6*this.NucSize));
            J = adapthisteq(rangeNormalise(im),'NumTiles',numtiles,'ClipLimit',0.01);
            
            fim = dogFiltND(J,[1,1]*this.NucSize/2);
            
            % find local maxima
            rmax = scaleRegionalMaxima2D(fim,this.NucSize,2);
            % remove extended plateaus (ie those that aren't fully removed
            % by the erosion operation) With the threshold applied first,
            % this might not be necessary..
            rmax = imdilate(...
                rmax & ~imreconstruct(imerode(rmax,diamondElement(2)),rmax),...
                diskElement(max(1,this.NucSize/8)));
            
            outim = {rmax.*fim;J};
            
        end
        
		% ======================================================================
		%> @brief Run the second part of the two-stage segmentation (gradient watershed)
		%>
		%> 
		%> @param this instance of the DoGNucAZSeg class
		%> @param ~ does not require the original image data
		%> @param inim the filtered image data from the first step
		%> @param ~ no label data required for this class
		%>
		%> @return L label matrix of segmented nuclei (as watershed returns labels, the applyLabelling metehod is not required)
		% ======================================================================
        function L = runStep2(this,~,inim,~)
            % need some mechanism by which filtered images can be passed
            % from one stage to the next
            rmax = inim{1};
            J = inim{2};
            
            bg = bwdist(rmax)>2.5*this.NucSize;
            % this also makes the watershed below faster, because far more
            % of the pixels are already assigned to background.
            % but it does have the effect of messing up segmentation of any
            % nuclei which are abnormally large
            if nnz(bg)==0
                warning('no background pixels left!')
            end
            
            M = openCloseByRecon(J,diskElement(this.NucSize/6));
            
            gg = gaussGradient2D(M,1.5);
            
            L = {markerWatershed(gg,rmax,bg)};
            
        end
        
		% ======================================================================
		%> @brief optional part of the TwoStageAZSeg interface which applies labelling to logical images
		%>
		%> 
		%> @param this instance of the DoGNucAZSeg class
		%> @param fim cell array of filtered images
		%> 
		%> @return L label matrix
		% ======================================================================
        function L = applyLabelling(this,fim)
            L = fim{1}; % the labelling has already been done
        end
        
        
    end
    methods (Static)
	% ======================================================================
		%> @brief get a description of the image processing operation to be displayed in GUI components
		%>
		%> @return str cell array of strings containing description of operation
		% ======================================================================
        function str = getDescription()
            str = {'Segmentation of small nuclei','',...
                ['Detect nuclei which tend to be small and clustering']};
        end
    end
end