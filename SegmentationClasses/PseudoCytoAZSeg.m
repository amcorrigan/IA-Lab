% Pseudo-cytoplasm segmentation
%> @file PseudoCytoAZSeg.m
%> @brief Pseudo-cytoplasm segmentation
%
%> @brief Tuneable parameters are the 'distance' threshold to expand, and the weight given to intensity
%
%> Expand around the nuclear seeds by a fixed amount of inverse
%> intensity - that is to say, expand further when the intensity is high
%> Can also do this with no input image, which is essentially a distance
%> transform

classdef PseudoCytoAZSeg < AZSeg
    % Pseudo-cytoplasm segmentation
    %
    % Expand around the nuclear seeds by a fixed amount of inverse
    % intensity - that is to say, expand further when the intensity is high
    % Can also do this with no input image, which is essentially a distance
    % transform
    
    properties
        %> Threshold 'distance' by which to expand around each nucleus
        Threshold = 50;
        %> Weighting given to intensity vs spatial distance
        IWeight = 0.8;
    end
    methods
        % ======================================================================
		%> @brief Class constructor
		%>
		%> Return the segmentation object with initial values for tuneable parameters
		%>
		%> @param thresh Threshold 'distance' by which to expand around each nucleus
		%> @param intensityWeight Weighting given to intensity vs spatial distance
		%>
		%> @return instance of the PseudoCytoAZSeg class.
		% ======================================================================
        function this = PseudoCytoAZSeg(thresh,intensityWeight)
           
            
            this@AZSeg({'Threshold','IWeight'},{'Distance Threshold','Intensity weighting'}...
                ,'Pseudo Cytoplasm',1,1,1);
            
            if nargin>0 && ~isempty(thresh)
                this.Threshold = thresh;
            end
            if nargin>1 && ~isempty(intensityWeight)
                this.IWeight = intensityWeight;
            end
            
            
        end
        
        % ======================================================================
		%> @brief Run the pseudo cytoplasm segmentation
		%>
		%> 
		%> @param this instance of the PseudoCytoAZSeg class
		%> @param imdata (optional) image data from which to use the intensity as inverse distance
		%> @param labdata input label matrix to expand
		%>
		%> @return L2 the expanded label matrix
		% ======================================================================
        function L2 = process(this,imdata,labdata)
            
            if iscell(labdata)
                labdata = labdata{1};
            end
            
            if ~isempty(imdata)
                if iscell(imdata)
                    imdata = imdata{1};
                    
                end
                im = adapthisteq(mat2gray(imdata),'numtiles',[8,8],'cliplimit',0.01);
                
                D = graydist(this.IWeight./im + (1-this.IWeight),labdata>0);
            else
                D = bwdist(labdata>0);
            end
            
            % want to stop at the given threshold value, and have
            % background after that
            
            bg = D>(1.5*this.Threshold) & ~imdilate(labdata>0,true(3));
            D(D>this.Threshold) = max(0,2*this.Threshold - D(D>this.Threshold));
            L2 = markerWatershed(D,labdata>0,bg);
            
        end
    end
    methods (Static)
        % ======================================================================
		%> @brief get a description of the image processing operation to be displayed in GUI components
		%>
		%> @return str cell array of strings containing description of operation
		% ======================================================================
		function str = getDescription()
            str = {'Pseudo cytoplasm segmentation','',...
                ['Expand around nuclei to a threshold distance.  If image data is' , ...
				' supplied, the distance is calculated as inverse intensity (ie expand further ',...
				'in bright regions), otherwise spatial distance is used.']};
        end
    end
end
