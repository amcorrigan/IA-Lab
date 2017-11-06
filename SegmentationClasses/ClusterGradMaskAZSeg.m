classdef ClusterGradMaskAZSeg < TwoStageAZSeg
    % same procedure as the cluster nuclei, but starting from the nuclear
    % seeds.
    % For the cell mask, we might want to weight the distance transforms a
    % little more strongly compared to the gradient?
    %
    % There are lots of parameters, but they're actually not very
    % sensitive, so will hopefully be very general
    
    properties
        RelThresh = 0.2;
        CellSize = 11;
        
        DistanceWeight1 = 5e-3;
        DistanceWeight2 = 0.01;
    end
    methods
        function this = ClusterGradMaskAZSeg(thr,siz,dweight1,dweight2)
             this = this@TwoStageAZSeg(...
                {'RelThresh','CellSize','DistanceWeight1','DistanceWeight2'},...
                {'Threshold','Cell size','Boundary effect','Centre effect'},...
                [1.5,2,2,2],'Clustered nucleus detection',1,0,1);
            
            if nargin>0 && ~isempty(thr)
                this.RelThresh = thr;
            end
            if nargin>1 && ~isempty(siz)
                this.CellSize = siz;
            end
            if nargin>2 && ~isempty(dweight1)
                this.DistanceWeight1 = dweight1;
            end
            if nargin>3 && ~isempty(dweight2)
                this.DistanceWeight2 = dweight2;
            end
            
            
        end
        function fim = runStep1(this,im,L)
            % calculate as much as we can in the first step, so that during
            % the tuning we don't have to recalculate things that we don't
            % need to.
            
            if iscell(im)
                im = im{1};
            end
            if iscell(L)
                L = L{1};
            end
            
            J = adapthisteq(rangeNormalise(im),'numtiles',[16,16],'cliplimit',0.05);
            
            D2 = bwdist(L>0);
%             imoc = openCloseByRecon(J,diskElement(this.NucRadius/3));
            gg = gaussGradient2D(J,2);
            
            fim = {J,D2,gg};
        end
        
        function L2 = runStep2(this,~,fim,L,~)
            
            if iscell(L)
                L = L{1};
            end
            
            bw = fim{1};
            D2 = fim{2};
            gg = fim{3};
            
            bw2 = imreconstruct(L>0,L>0 | bw);
            D1 = bwdist(~bw2);
            
            gradim = gg - this.DistanceWeight1*D1 + this.DistanceWeight2*D2;
            
            % round to the nearest odd number for the erosion
            bg = imerode(~bw2,true(2*floor(this.CellSize/2) + 1));
%             bg = imerode(temp,true(5));
%             gradim(temp & ~bg) = 50;
            L2 = markerWatershed(gradim,L>0,bg);
            
%             L2(bw2==0) = 0;
            
            % need to rescale so that the labels in L and L2 match up
            L2 = matchLabels(L2,L);
        end
        
    end
end
