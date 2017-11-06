classdef (Abstract) cPixelDataInterface < handle
    % interface for an image, defining the operations which are common to
    % all types of image
    
    % First question - should cImage be a handle?
    % My (AMC) guess would be yes, so that different images can be passed
    % around (in multi-channel arrays) without making multiple copies of
    % the pixel data.
    % But this does mean that care will have to be taken when doing image
    % processing to ensure that the raw data isn't accidentally modified
% %     properties (Dependent)
% %         SizeX
% %         SizeY
% %     end
    
    methods
        vSize = getImSize(this) % return the dimensionality of the image, including all dimensions
        
        n = getNDim(this)   % get the number of dimensions (XYCZT)
                           % we have not decided yet regarding sequences
                           
% %         sizeX = get.SizeX(this)
% %         sizeY = get.SizeY(this)
        
        imdata = rawdata(this)
        
        showImage(this)
        
        dispObj = defaultDisplayObject(this,panelh,contrastObj,dispInfo)
        
        % Return a version of the image ready for display in a 2D viewer
        % (but not viewer specific)
        % the details of this depend on whether it is multi-channel or not
        im = getData2D(this)
        
        im = getData3D(this)
        
        psiz = getPixelSize(this)
        
        function val = getNativeColour(this,ind)
            val = [1,1,1];
        end
    end
    
end