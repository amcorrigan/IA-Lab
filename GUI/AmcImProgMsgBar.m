classdef AmcImProgMsgBar < AmcProgMsgBar
    % add an image to the message bar
    % this can't be entirely generic because the location of the image
    % depends on whether we have text or not
    
    % an option here would be to allow the choice of the java image panel
    % to be supplied, for the rotating dots animation
    
    properties  
        imAx
        imh % is this too much?
    end
    methods
        function obj = AmcImProgMsgBar(im,varargin)
            obj = obj@AmcProgMsgBar(varargin{:});
            
            % move the other elements around to make room for the image
            % axes
            set(obj.msgh,'position',[0.03,0.75,0.94,0.2])
            set(obj.progAx,'position',[0.05,0.06,0.9,0.04])
            
            obj.imAx = axes('position',[0.02,0.15,0.96,0.55],'parent',obj.fig);
            
            if nargin>0 && ~isempty(im)
                updateImage(obj,im);
            end
            axis(obj.imAx,'off');
        end
        
        function updateImage(obj,im)
            if size(im,3)==1
                im = repmat(im,[1,1,3]);
            end
            if ishandle(obj.imh)
                delete(obj.imh)
            end
            obj.imh = imagesc('parent',obj.imAx,'cdata',flipud(im));
            axis(obj.imAx,'equal');
        end
    end
    
end
