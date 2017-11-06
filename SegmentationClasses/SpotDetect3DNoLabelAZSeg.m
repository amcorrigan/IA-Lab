classdef SpotDetect3DNoLabelAZSeg < OneStageAZSeg
    % Detection of spots (eg DNA damage, FISH transcription spots) in 3D, without masking by cell/object region.
    properties
        SpotSizeXY
        SpotSizeZ
        SpotThreshold
    end
    methods
        function this = SpotDetect3DNoLabelAZSeg(spotsizexy,spotsizez, thresh)
            % set up the interactive parameter tuning
            this = this@OneStageAZSeg({'SpotSizeXY','SpotSizeZ','SpotThreshold'},...
                {'Spot Size in XY','Spot Size in Z','Intensity threshold'},[1,1,1.5],...
                '3D spot detection',1,0,1); % 1 input channel, 1 label channel, 1 output channel
            
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
        
        function outim = runStep1(this,im,~)
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            % depending on the density, could customise the lengthscale
            % subtracted off first, to improve the detection of clustered
            % spots
            
            try
            fim = dogFiltND(im,[this.SpotSizeXY,this.SpotSizeXY,this.SpotSizeZ]);
            catch me
                rethrow(me)
            end
            lmax = amcRegionalMaxima(fim,{diskElement(3),ones(1,1,3)});
            
            % can also do the removal of extended plateaus here before the
            % threshold
% %             lmax = lmax & ~imreconstruct(imerode(lmax,diamondElement(2)),lmax);
            
            % imreconstruct takes a very long time for 3D images, so let's
            % try a simple opening instead? No, that won't guarantee
            % keeping the shapes the same..
            lmax = lmax & ~imreconstruct(imerode(lmax,diamondElement(2)),lmax);
            % this might be useful enough to incorporate into
            % amcRegionalMaxima above
            
            
            outim = lmax.*fim; % this is ready to be thresholded
        end
        
        function fim = processForDisplay(this,im)
            % the default processing of a given image for display of the QC
            % image.  This will be rangeNormalise for most cases, but eg
            % for the viewRNA some contrast adjustment is necessary for the
            % high dynamic range of the spot intensities
            
            if iscell(im)
                fim = cell(size(im));
                for ii = 1:numel(im)
                    fim{ii} = this.processForDisplay(im{ii}); % this could be sent
                        % to a sub-method, but is there any point?
                end
            else
                fim = rangeNormalise(im).^(1/3);
            end
        end
    end
end