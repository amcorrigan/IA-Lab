classdef BlurMetricAZMeasure < AZMeasure
    % operate on a whole image, to determine if there is a lot of blurring
    properties
        ScaleFactor = 0.25;
        BlurScale = 9;
    end
    methods
        function this = BlurMetricAZMeasure(prefix,blscale,scfact)
            if nargin<1 || isempty(prefix)
                prefix = '';
            end
            this@AZMeasure(prefix);
            
            if nargin>1 && ~isempty(blscale)
                this.BlurScale = blscale;
            end
            if nargin>2 && ~isempty(scfact)
                this.ScaleFactor = scfact;
            end
            
            this.OutputType = 'Field';
            this.NumInputLabels = 0;
            this.NumInputImages = [];
        end
        
        function stats = measure(this,~,imdata)
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            for ii = 1:numel(imdata)
                im = imresize(imdata{ii},this.ScaleFactor);
                stats.([this.Prefix,'BlurMetric',num2str(ii)]) = amcBlurMetric(im,this.BlurScale);
            end
        end
    end
end
