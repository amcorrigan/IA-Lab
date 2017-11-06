classdef DenseNucAZSeg < TwoStageAZSeg %AZSeg
    % Difference of Gaussians to find centres, gradient watershed for segmentation.
    properties
        NucSize = 50;
        HoleSize = 5;
        RelThreshold = 0;
    end
    methods
        function this = DenseNucAZSeg(nucsiz,thresh)
            % set up the interactive parameter tuning
            this = this@TwoStageAZSeg({'NucSize','RelThreshold','HoleSize'},...
                {'Nucleus Size','Threshold Adjustment','Size of interior holes'},[2,1.5,1],...
                'Nucleus Detection',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(nucsiz)
                this.NucSize = nucsiz;
            end
            if nargin>1 && ~isempty(thresh)
                this.RelThreshold = thresh;
            end
            
        end
        
        function outim = runStep1(this,im,~)
            % this kind of input checking can be farmed out to specialized
            % superclasses
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            % rather than just boosting the contrast, want to specifically
            % look to suppress fluctuations inside nuclei but keep edges.
            
            % how slow is imfill?
            fillim = imfill(im);
            
            % then try smoothing the interior
            smim = amcBilateral2D(fillim,[],this.HoleSize,0.07,16,4);
            smim2 = amcBilateral2D(smim,[],this.HoleSize,0.07,16,4);
            th = multithresh(smim2);
            adjim = smim2-th;
            
            outim = {adjim};
        end
        
        function L = runStep2(this,~,inim,~)
            
            bw = inim{1};
            Dboth = bwdist(imdilate(bw,diamondElement) & ~bw);
            
            % the level of smoothing can be linked to the height, bilateral
            % style.
            smD = gaussFiltND(Dboth.*double(bw),this.NucSize*0.2*[1,1]);
            lmax = imregionalmax(smD);
            mergemax = mergeForegroundPoints(lmax,this.NucSize/3);
            
            bg = Dboth>3 & ~bw;
            L = markerWatershed(-Dboth,mergemax,bg);
            
            L(~bw) = 0;
        end
        
        function L = applyLabelling(this,fim)
            L = fim; % the labelling has already been done
        end
        
        
    end
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of dense stained nuclei','',...
                ['Detect nuclei can be large and dense, and have holes in (eg nucleoli)']};
        end
    end
end