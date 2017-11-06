classdef CytoFibreAZSeg < TwoStageAZSeg
    % expand around nuclei using the inverse of intensity as a distance
    % measure.
    properties
        SmoothSize = 2;
        Threshold = 0.1;
    end
    methods
        function this = CytoFibreAZSeg(smoothsize, thresh)
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
            
            % other ways of normalising, doesn't have to be adaptive
            J = adapthisteq(rangeNormalise(im),'NumTiles',[8,8],'ClipLimit',0.01);
            
% %             smJ = gaussFiltND(J,[1,1]*this.SmoothSize);
% %             smJ = amcBilat(J,[],this.SmoothSize,0.1,16,this.SmoothSize);
            smJ = amcBilateral2D(J,[],this.SmoothSize,0.1,16,this.SmoothSize);
            
            outim = {smJ;smJ};
        end
        
        function Lcell = runStep2(this,~,inim,L)
            
            if iscell(L)
                L = L{1};
            end
            
            
            Gint = 1./(0.05+inim{2});
            Gint(~inim{1}) = 40;
            
            D2 = bwdist(~inim{1});
            Dw = this.sigmoidf(D2,-10,16);
            Gint = Dw.*Gint;
            
            try
            D = graydist(Gint,L>0);
%             Duse = graydist(Gint,L>0);
            catch ME
                rethrow(ME)
            end
            
            % the cost to the narrowness of the fibres can be added here
            % weighting the graydist values, or it could be applied to the
            % Gint values, before calculating the grayscale distance
            % transform
            
            % doing it the first way appears to give better results
            
            D2 = bwdist(~inim{1});
            Dw = this.sigmoidf(D2,-10,16);
            Duse = Dw.*D;
            L0 = watershed(imimposemin(Duse,L>0));
            
            Ltemp = L0;
            Ltemp(L==0) = 0;
            % reorder so that the values of L and L0 are matched
            stats = regionprops(Ltemp,L,'MeanIntensity');
            idx = [0;[stats.MeanIntensity]'];
            
            Lcell = idx(L0+1);
            
            Lcell(~inim{1} & L==0) = 0;
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
        
        function y = sigmoidf(x,sc,offset)

            if nargin<3 || isempty(offset)
                offset = 0;
            end
            if nargin<2 || isempty(sc)
                sc = 1;
            end

            y = 1./(1+exp(-(x-offset)/sc));
        end
    end
end
