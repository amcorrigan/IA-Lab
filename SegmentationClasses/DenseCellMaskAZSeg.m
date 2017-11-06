classdef DenseCellMaskAZSeg < TwoStageAZSeg
    % expand around nuclei using the inverse of intensity as a distance
    % measure.
    properties
        SmoothSize = 2;
        Threshold = 0.2;
        
        DoHistEq = false;
    end
    methods
        function this = DenseCellMaskAZSeg(smoothsize, thresh)
            % set up the interactive parameter tuning
            this = this@TwoStageAZSeg({'SmoothSize','Threshold'},...
                {'Smoothing scale','Threshold Adjustment'},[1,1.5],...
                'Cytoplasm detection',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(smoothsize)
                this.SmoothSize = smoothsize;
            end
            if nargin>1 && ~isempty(thresh)
                this.Threshold = thresh;
            end
            
        end
        
        function outim = runStep1(this,im,~)
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            if this.DoHistEq
%                 im = histeq(mat2gray(im),1000);
                im = adapthisteq(mat2gray(im),'numtiles',[8,8],'cliplimit',0.02);
            else
                im = im.^0.2;
            end
            
            % how slow is imfill?
%             fillim = imfill(im);
            
            % then try smoothing the interior
            smim = amcBilateral2D(im,[],this.SmoothSize,0.07,16,4);
            
            % not sure this threshold will be very consistent for sparse vs
            % dense fields..
            th = multithresh(smim);
            adjim = smim-th;
            
            outim = {adjim,smim};
        end
        
        function Lcell = runStep2(this,im,inim,L)
            
            while iscell(L)
                L = L{1};
            end
            bw = inim{1};
            bw = bw | (L>0);
            
            Dboth = bwdist(imdilate(bw,diamondElement) & ~bw);
            
            % look at scaling the intensity later
            bg = Dboth>=2 & ~bw;
            
            basinIm = -inim{2};
            basinIm(~bw) = - 5*Dboth(~bw);
            basinIm(bw) = basinIm(bw) - 0.01*Dboth(bw);
            
            L0 = markerWatershed(basinIm,L>0,bg);
            
            Lcell = matchLabels(L0,L);
        end
        
        function L = applyLabelling(this,fim)
            L = fim;
        end
        
        
    end
    methods (Static)
        function str = getDescription()
            str = {'Cytoplasm segmentation from nuclei seeds','',...
                ['Detect cytoplasm which may have a complex shape']};
        end
    end
end
