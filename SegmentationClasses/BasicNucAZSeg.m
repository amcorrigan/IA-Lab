% Basic nuclei detection, based on smoothing and thresholding
%> @file BasicNucAZSeg.m
%> @brief Basic nuclei detection, based on smoothing and thresholding
%> @brief Tuneable parameters are the approximate radius of nuclei, and relative threshold
%> The nuclear radius is used to split touching objects using a distance transform
%> The relative threshold is the adjustment relative to threshold calculated using Otsu's method
classdef BasicNucAZSeg < AZSeg
    % Basic nuclei detection
	% Based upon smoothing, thresholding and then breaking apart touching nuclei
    
    properties
		%> Radius of nuclei
        NucRadius = 32 % rough radius of desired objects
		%> Threshold adjustment relative to Otsu level
        RelThresh = 0 % threshold relative to Otsu
        
    end
    methods
		% ======================================================================
		%> @brief Class constructor
		%>
		%> Return the segmentation object with initial values for tuneable parameters
		%>
		%> @param nucrad Radius of nuclei in pixels
		%> @param pthr Threshold adjustment relative to Otsu level
		%>
		%> @return instance of the BasicNucAZSeg class.
		% ======================================================================
        function this = BasicNucAZSeg(nucrad,pthr)
            % set up the interactive parameter tuning
            this = this@AZSeg({'NucRadius','RelThresh'},...
                {'Radius of Nuclei','Threshold Adjustment'},...
                'Nucleus Detection',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(nucrad)
                this.NucRadius = nucrad;
            end
            if nargin>1 && ~isempty(pthr)
                this.RelThresh = pthr;
            end
            
        end
        
		% ======================================================================
		%> @brief Run the nuclear segmentation
		%>
		%> 
		%> @param this instance of the BasicNucAZSeg class
		%> @param im image data (single channel, 2D)
		%> @param ~ no label data required
		%>
		%> @return L label matrix of detected nuclei
		% ======================================================================
        function L = process(this,im,~,~)
            % original working code is in faintnucseg.m
            
            % this kind of input checking can be farmed out to specialized
            % superclasses
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            % link the smoothing scale to the nuclear size
            smoothScale = max(1,this.NucRadius/4);
            blim = amcBilateral2D(sqrt(im),[],smoothScale,0.1,16,4);
            
            % For fixed images, a basic threshold can be enough
            bw = blim>((1+this.RelThresh)*amcGrayThresh(blim));
            
            % morphological smoothing
            bwoc = imclose(imopen(bw,diskElement(8)),diskElement(8));
            bwoc2 = openCloseByRecon(bw,diskElement(8));
            bwuse = bwoc & bwoc2;
            
            D = bwdist(~bwuse);
            smD = gaussFiltND(D,0.5*this.NucRadius*[1,1]);
            dogD = smD - gaussFiltND(D,0.5*this.NucRadius*[1.6,1.6]);
            
            dogD = imreconstruct(dogD-0.5,dogD);
            
            lmax = imregionalmax(dogD) & D>5;
%             newbw = imreconstruct(lmax,bwuse);
            
            Dbg = bwdist(bwuse);
            
%             bg = bwmorph(~bwuse,'skel',Inf);
            bg = bwmorph(~bwuse,'skel',10);
            
            L = {double(markerWatershed(-D-Dbg,lmax,bg))};
            
        end
    end
    methods (Static)
		% ======================================================================
		%> @brief get a description of the image processing operation to be displayed in GUI components
		%>
		%> @return str cell array of strings containing description of operation
		% ======================================================================
        function str = getDescription()
            str = {'Segmentation of fixed nuclei','',...
                ['Detect nuclei that have been stained by DAPI, Hoechst or similar.',...
                ' Basic smoothing and thresholding, followed by attempting to break',...
                ' apart touching nuclei.']};
        end
    end
end
    