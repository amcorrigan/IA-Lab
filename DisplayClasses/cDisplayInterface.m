classdef cDisplayInterface < handle
    % a generic display class
    % more detail will be added as we learn what is required
    
    % For almost all applications, it seems to make sense to keep a
    % reference to the image object in the display object - eg contrast
    % adjustment, subsequent segmentation without having to reopen the
    % images.  Is this practical? Or will we quickly run out of memory?
    events
        closeRequest
        imageEvent
    end
    methods
        showImage(this,imObj) % show the image
        isCompatible(this,imObj) % check if the image is compatible to be displayed using this class
        
        cdata = getThumbnail(this,siz);
        
        gh = getSnapshotHandle(this);
        
        function info = getInfo(this) % get information about the display which can be passed to another display
            info = [];
        end
        
        function scrollfun(this,src,evt)
            % do nothing here, but the display interface is expected to
            % have one.
        end
        
        function addChannelLabels(this,chanlabels)
            % by default, don't do anything with these..
        end
    end
end