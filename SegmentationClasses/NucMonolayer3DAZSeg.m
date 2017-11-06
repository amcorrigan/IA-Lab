% Perform 3D segmentation of nuclei in a monolayer from a 3D image
%> @file NucMonolayer3DAZSeg.m
%> @brief Perform 3D segmentation of nuclei in a monolayer from a 3D image
% ======================================================================
%> @brief This works best if the nuclei do not significantly overlap in z
%
%> Nuclei are first segmented in XY, followed by finding the top and bottom
%> of each column of pixels, and morphological smoothing
% ======================================================================
classdef NucMonolayer3DAZSeg < TwoStageAZSeg
    properties
        NucSize = 50;
        HoleSize = 5;
        RelThreshold = 0;
    end
    methods
        function this = NucMonolayer3DAZSeg(nucsiz,thresh)
            % set up the interactive parameter tuning
            this = this@TwoStageAZSeg({'NucSize','RelThreshold','HoleSize'},...
                {'Nucleus Size','Threshold Adjustment','Size of interior holes'},[2,1.5,1],...
                '3D nuclei Detection',1,0,1); % 1,0,1 is the default, could be left out
            
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
            
            im2d = max(im,[],3);
            if ~isa(im2d,'double')
                im2d = double(im2d);
            end
            
            % rather than just boosting the contrast, want to specifically
            % look to suppress fluctuations inside nuclei but keep edges.
            
            % how slow is imfill?
            fillim = imfill(im2d);
            
            % then try smoothing the interior
            smim = amcBilateral2D(fillim,[],this.HoleSize,0.07,16,4);
            smim = amcBilateral2D(smim,[],this.HoleSize,0.07,16,4);
            th = multithresh(smim); % automatic threshold might be OK when we know there is plenty of background
            adjim = smim-th;
            
            outim = {adjim};
        end
        function L3 = runStep2(this,im,inim,~)
            if iscell(im)
                im = im{1};
            end
            
            im2d = mean(im,3); % use the mean this time for consistency with previous methods
            
            bw = inim{1};
            
            % remove objects smaller than a certain size?
            % use the supplied nucleus size
            % remember this is area at the moment, not volume
            minarea = 0.2 * this.NucSize^2;
            bw = bwareafilt(bw,[minarea,Inf]);
            
            Dboth = bwdist(imdilate(bw,diamondElement) & ~bw);
            
            % the level of smoothing can be linked to the height, bilateral
            % style.
            smD = gaussFiltND(Dboth.*double(bw),this.NucSize*0.2*[1,1]);
            lmax = imregionalmax(smD);
            mergemax = mergeForegroundPoints(lmax,this.NucSize/3);
            
            bg = Dboth>3 & ~bw;
            L = markerWatershed(-Dboth,mergemax,bg);
            
            L(~bw) = 0;
            
            
            % having done the monolayer segmentation, now add 3D
            % information
% %             if obj.zinterp~=1
% %                 userim = resize3(im,[1,1,obj.zinterp].*size(im),'linear');
% %             else
% %                 userim = im; % userim could be passed to znormalise
% %             end
            
            im = gaussFiltND(im,[4,4,2]);
            nim = zNormalise(im,0.5);
%             clear temp
%             nim = zNormalise(gaussFiltND(im,[4,4,2]),0.5);
            
            nr = adaptNormaliseScaled(...
                openCloseByRecon(im2d,diskElement(4)),this.NucSize,0.3,4);
            nim = bsxfun(@times,nr,nim);

            % for the confocal try squaring nim2 so that high intensity gradients are
            % weighted more than low ones.
            gg = gaussGradient3D(nim.^2,[3,3,1],19);
            clear nim

%             L3 = add3DLabelsSeed(L,im,[],gg);
            L3 = add3DLabelInfo(L,im,[],gg);
            
        end
        
        function L = applyLabelling(this,fim)
            L = fim; % the labelling has already been done
        end
        
        
    end
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of dense stained nuclei in 3 dimensions','',...
                ['Detected nuclei can be large and dense, and have holes in (eg nucleoli)']};
        end
    end
end
