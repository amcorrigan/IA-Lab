classdef CellMaskAZSeg < AZSeg
    % expand around a foreground marker to find the cell cytoplasm in 2D
    % using the fluorescent cell mask
    % Generally, since this a post-fixation stain, the levels between cells
    % will be very similar
    % This isn't finished yet, it's basically taken code from elsewhere and
    % hasn't 
    properties
        IntensityThresh = 0.07;
        SmoothScale = 5;
    end
    methods
        function this = CellMaskAZSeg(ithr,smsc)
            this = this@AZSeg({'IntensityThresh','SmoothScale'},...
                {'Intensity Threshold','Smoothing Scale'},...
                'Cell Mask',1,1,1);
            
            % AZSeg can handle this
            if nargin>0 && ~isempty(ithr)
                this.IntensityThresh = ithr;
            end
            if nargin>1 && ~isempty(smsc)
                this.SmoothScale = smsc;
            end
            
            this.DoLabelling = false;
        end
        
        function L = process(this,im,labData)
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            if iscell(labData)
                labData = labData{1};
            end
            % end of input checking boilerplate
            
            % a basic threshold will probably do fine
            smoothIm = gaussFiltND(im,[1,1]*this.SmoothScale);
            J = adapthisteq(rangeNormalise(smoothIm),'cliplimit',0.01);
            bw = imreconstruct(labData>0,J>this.IntensityThresh);
            
            L = {double(watershed(imimposemin(-bwdist(~bw)+400*double(bw),labData>0))).*double(bw)};
            
        end
    end
end