classdef DenseCellNoNucAZSeg < TwoStageAZSeg %AZSeg
    % Densely clustered cells with cell marker but no nucleus marker.
    % Threshold + bwdist to find centres, gradient watershed for
    % segmentation
    properties
        CellSize = 12;
        Threshold = 0.1;
    end
    methods
        function this = DenseCellNoNucAZSeg(cellsiz,thresh)
            % set up the interactive parameter tuning
            this = this@TwoStageAZSeg({'CellSize','Threshold'},...
                {'Cell Size','Threshold Adjustment'},[1,1.5],...
                'Cell Detection',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(cellsiz)
                this.CellSize = cellsiz;
            end
            if nargin>1 && ~isempty(thresh)
                this.Threshold = thresh;
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
            
            numtiles = ceil(size(im)/(6*this.CellSize));
            J = adapthisteq(rangeNormalise(im),'NumTiles',numtiles,'ClipLimit',0.01);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            t=multithresh(J,2);
            fim=bwdist(~(J>t(2)));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % find local maxima
            rmax = scaleRegionalMaxima2D(fim,this.CellSize,2);
            % remove extended plateaus (ie those that aren't fully removed
            % by the erosion operation) With the threshold applied first,
            % this might not be necessary..
            rmax = imdilate(...
                rmax & ~imreconstruct(imerode(rmax,diamondElement(2)),rmax),...
                diskElement(max(1,this.CellSize/8)));
            
            outim = {rmax.*fim;J};
            
        end
        
        function L = runStep2(this,~,inim,~)
            % need some mechanism by which filtered images can be passed
            % from one stage to the next
            rmax = inim{1};
            J = inim{2};
            
            bg = bwdist(rmax)>2.5*this.CellSize;
            % this also makes the watershed below faster, because far more
            % of the pixels are already assigned to background.
            % but it does have the effect of messing up segmentation of any
            % nuclei which are abnormally large
            if nnz(bg)==0
                warning('no background pixels left!')
            end
            
%             t=multithresh(J,2);
%             t2=multithresh(J(J>t(2)),1);
%             J(J>t2(1))=t2(1);
            
            
            
            M = openCloseByRecon(J,diskElement(this.CellSize/6));
            
            gg = gaussGradient2D(M,1.5);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            t=multithresh(J,2);
            bwd=bwdist(~(J>t(2)));
            %gg=gg./(bwd+1);
            gg=gg.*bwdist(rmax)./(bwd+1);
            L = {markerWatershed(gg,rmax,bg,1000)};
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
        end
        
        function L = applyLabelling(this,fim)
            L = fim{1}; % the labelling has already been done
        end
        
        
    end
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of cells','',...
                ['Detect clustering cells without nucleus marker']};
        end
    end
end