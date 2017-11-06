classdef ThroughputParser < handle
    % interface for accessing parser images in an automated high throughput
    % way
    methods
        N = getNumImages(this);
        [imobj,imInfo] = getImage(this,idx);
        
        function pixsize = getPixelSize(this)
            pixsize = [1,1];
        end
    end
end