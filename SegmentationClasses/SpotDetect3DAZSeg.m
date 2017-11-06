classdef SpotDetect3DAZSeg < OneStageAZSeg
    % Detection of spots (eg DNA damage, FISH transcription spots) in 3D, within cells/objects.
    properties
        SpotSizeXY
        SpotSizeZ
        SpotThreshold
    end
    methods
        function this = SpotDetect3DAZSeg(spotsizexy,spotsizez, thresh)
            % set up the interactive parameter tuning
            this = this@OneStageAZSeg({'SpotSizeXY','SpotSizeZ','SpotThreshold'},...
                {'Spot Size in XY','Spot Size in Z','Intensity threshold'},[1,1,1.5],...
                '3D spot detection',1,1,1); % 1 input channel, 1 label channel, 1 output channel
            
            if nargin>0 && ~isempty(spotsizexy)
                this.SpotSizeXY = spotsizexy;
            end
            if nargin>1 && ~isempty(spotsizez)
                this.SpotSizeZ = spotsizez;
            end
            
            if nargin>2 && ~isempty(thresh)
                this.SpotThreshold = thresh;
            end
            
            % at some point this will be used to tell the tuner how to
            % display the output, but it's not used yet
            this.ReturnType = 'point';
            
        end
        
        function outim = runStep1(this,im,L)
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            if nargin<3
                L = [];
            end
            
            if iscell(L)
                L = L{1};
            end
            
            % depending on the density, could customise the lengthscale
            % subtracted off first, to improve the detection of clustered
            % spots
            
            fim = dogFiltND(im,[this.SpotSizeXY,this.SpotSizeXY,this.SpotSizeZ]);
            lmax = amcRegionalMaxima(fim,{diskElement(3),ones(1,1,3)});
            
            % can also do the removal of extended plateaus here before the
            % threshold
            lmax = imdilate(...
                lmax & ~imreconstruct(imerode(lmax,diamondElement(2)),lmax),...
                diamondElement(1));
            % this might be useful enough to incorporate into
            % amcRegionalMaxima above
            
            if ~isempty(L)
                % also apply the existing label matrix, if there is one
                lmax = bsxfun(@and, lmax, L>0); % expands L to 3D if it's only 2D
            end
            
            outim = lmax.*fim; % this is ready to be thresholded
        end
        
    end
end