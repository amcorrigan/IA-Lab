classdef TestNucAZSeg < TwoStageAZSeg
    % first build of segmentation class, taking faint nuclei as an example
    %
    % The interface for interactive settings should be abstracted once it
    % has been settled on, but it basically means defining which properties
    % can be tuned
    
    properties
        NucRadius = 32 % rough radius of desired objects
        RelThresh = 0 % threshold relative to Otsu
        
    end
    methods
        function this = TestNucAZSeg(nucrad,pthr)
            % set up the interactive parameter tuning
            this = this@TwoStageAZSeg({'NucRadius','RelThresh'},...
                {'Radius of Nuclei','Threshold Adjustment'},[1,1.5],...
                'Nucleus Detection',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(nucrad)
                this.NucRadius = nucrad;
            end
            if nargin>1 && ~isempty(pthr)
                this.RelThresh = pthr;
            end
            
        end
        
        function fim = runStep1(this,im,~)
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
%             bw = blim>((1+this.RelThresh)*amcGrayThresh(blim));
            fim = blim/amcGrayThresh(blim) - 1;
            
        end
        
        function L = runStep2(this,im,fim,~,~)
            
            % morphological smoothing
            bwoc = imclose(imopen(fim,diskElement(8)),diskElement(8));
            bwoc2 = openCloseByRecon(fim,diskElement(8));
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
            
            L = double(markerWatershed(-D-Dbg,lmax,bg));
            
        end
        
    end
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of fixed nuclei','',...
                ['Detect nuclei that have been stained by DAPI, Hoechst or similar.',...
                ' Basic smoothing and thresholding, followed by attempting to break',...
                ' apart touching nuclei.']};
        end
    end
end
    