classdef AmcAutoImProg < AmcImProgMsgBar
    properties
        iconData
    end
    methods
        function obj = AmcAutoImProg(iconData,varargin)
            % sort out input checking later

            % get the first image of the list to send to the super class constructor
            im = iconData.getImage(1);
            obj = obj@AmcImProgMsgBar(im,varargin{:});
            obj.iconData = iconData;
        end

        function updateProg(obj,prog)
            % want to override the superclass to update the image as well whenever the
            % prog is updated

            % calculate the nearest image in the icon store
            ind = floor(prog*(getNumImages(obj.iconData)-1)) + 1;

            im = obj.iconData.getImage(ind);
            updateProg@AmcProgBar(obj,prog);
            obj.updateImage(im);
        end
    end
end
