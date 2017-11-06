classdef ImgLoader < handle
    % Interface for loading images
    % At the moment, this is the bare minimum for what is required
    
    % More specialized classes can store meta-data and additional
    % information
    
    methods
        im = getImage(this, varargin);
%       loadCurrentImage(this, mode); % this is not compatible with parallel
%       reading.
        
        N = getTotalNumChan(this);
        aName = getTitle(this);
        
        % placeholder function to ensure compatibility with YEMain
        function thumbObj = setThumbnail(this,src,evt)
            IAHelp();
            thumbObj = [];
        end
    end
end