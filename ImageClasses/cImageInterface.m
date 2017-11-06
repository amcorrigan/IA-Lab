classdef (Abstract) cImageInterface < cPixelDataInterface
    % interface for an image, defining the operations which are common to
    % all types of image
    
    % First question - should cImage be a handle?
    % My (AMC) guess would be yes, so that different images can be passed
    % around (in multi-channel arrays) without making multiple copies of
    % the pixel data.
    % But this does mean that care will have to be taken when doing image
    % processing to ensure that the raw data isn't accidentally modified
    properties
%         NativeColour
    end
    
   
end