classdef cImageInstance < cImageInterface
    % a quick way to implement all the functions in the cImageInterface, so
    % that we can inherit a child class from this withOUT implement every
    % methods.
    methods
        function vSize = getImSize(this) % return the dimensionality of the image, including all dimensions
            error('Method not yet implemented')
        end
        
        function n = getNDim(this)   % get the number of dimensions (XYCZT)
                           % we have not decided yet regarding sequences
            error('Method not yet implemented')
        end          
        function sizeX = getSizeX(this)
            error('Method not yet implemented')
        end          
        function sizeY = getSizeY(this)
            error('Method not yet implemented')
        end          
        
        function imdata = rawdata(this)
            error('Method not yet implemented')
        end          
        
        function showImage(this)
            error('Method not yet implemented')
        end
        
        function im = getData2D(this)
            error('Method not yet implemented')
        end
        
        function im = getData3D(this)
            error('Method not yet implemented')
        end
    end
    
end