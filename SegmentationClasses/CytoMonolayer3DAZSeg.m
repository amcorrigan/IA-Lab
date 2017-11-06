% Perform 3D segmentation of 3D cells in a monolayer from cellmask and nuclear labels
%> @file CytoMonolayer3DAZSeg.m
%> @brief Perform 3D segmentation of 3D cells in a monolayer from cellmask and nuclear labels
% ======================================================================
%> @brief This works best if the cells do not significantly overlap in z
%
%> Cells are first segmented in XY, followed by finding the top and bottom
%> of each column of pixels, and morphological smoothing
% ======================================================================
classdef CytoMonolayer3DAZSeg < TwoStageAZSeg
    properties
        %> Threshold adjustment relative to Otsu-calculated level
        RelThreshold = 0;
        %> The rough size of intracellular holes in the cellmask, which are attempted to be filled in.
        HoleSize = 5;
    end
    methods
        function this = CytoMonolayer3DAZSeg(thresh)
            
            this = this@TwoStageAZSeg({'RelThreshold','HoleSize'},...
                {'Threshold Adjustment','Size of interior holes'},[1.5,1],...
                '3D cytoplasm detection',1,1,1);
            
            if nargin>0 && ~isempty(thresh)
                this.RelThreshold = thresh;
            end
            
        end
        
        function outim = runStep1(this,im,L)
            % don't need the label for now
            
            if iscell(im)
                im = im{1};
            end
            
            th = multithresh(im);
            % the baseline threshold value is calculated from the whole
            % image, to ensure we've got some background in it
            
            im2d = double(max(im,[],3));
            
            % then try smoothing the interior
            smim = amcBilateral2D(im2d,[],this.HoleSize,0.07,16,4);
            smim = amcBilateral2D(smim,[],this.HoleSize,0.07,16,4);
            
            adjim = smim - double(th);
            
            outim = {adjim,smim};
        end
        
        function Lcell = runStep2(this,im,inim,L)
            if iscell(im)
                im = im{1};
            end
            if iscell(L)
                L = L{1};
            end
            im2d = mean(im,3);
            
            % get the thresholded image
            % the threshold should be set so as to get as much foreground
            % as possible, at the expense of letting through some
            % background (rather than the other way around)
            bw = imreconstruct(max(L>0,[],3),inim{1});
            
            
            bg = bwdist(bw)>4;
            
% %             gradim = gaussGradient2D(inim{2},2);
% %             
% %             L2D = markerWatershed(gradim,max(L>0,[],3),bg);
% %             
            L2D = markerWatershed(-inim{2},max(L>0,[],3),bg);

            im = gaussFiltND(im,[4,4,2]);
            nim = zNormalise(im,0.5);
%             clear temp
%             nim = zNormalise(gaussFiltND(im,[4,4,2]),0.5);
            
            nr = adaptNormaliseScaled(...
                openCloseByRecon(im2d,diskElement(4)),8*this.HoleSize,0.3,4);
            nim = bsxfun(@times,nr,nim);

            % for the confocal try squaring nim2 so that high intensity gradients are
            % weighted more than low ones.
            gg = gaussGradient3D(nim.^2,[3,3,1],19);
            clear nim

            Lcell = add3DLabelInfo(L2D,im,L>0,gg);
            
            Lcell = matchLabels(Lcell,L);
        end
        
        function L = applyLabelling(this,fim)
            L = fim; % the labelling has already been done
        end
        
    end
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of cellmask stained cells in 3 dimensions','',...
                ['Detect nuclei can be large and dense, and have holes in (eg nucleoli)']};
        end
    end
end
