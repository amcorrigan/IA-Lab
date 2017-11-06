classdef AZMeasurePixels < AZMeasure
    % parent class allowing pixel size information to be passed to the measurement class.
    properties
        PixelSize = [1,1,1];
    end
    methods
        function this = AZMeasurePixels(propPrefix,pixsize)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(pixsize)
                this.setPixelSize(pixsize);
            end
        end
        function setPixelSize(this,pixsize)
            if nargin<2 || isempty(pixsize)
                return;
            end
            
            % don't try to second guess the number of dimensions at this
            % point...
% %             if numel(pixsize)==1
% %                 pixsize = [1,1,1]*pixsize;
% %             elseif numel(pixsize)==2
% %                 pixsize = [pixsize(:)',1];
% %             end
            
            this.PixelSize = pixsize;
        end
    end
end
