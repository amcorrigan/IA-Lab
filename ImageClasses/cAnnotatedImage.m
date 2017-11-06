classdef cAnnotatedImage < cPixelDataInterface
    % version of cImage which has separate treatments for image data, label
    % data, mask data and potentially filtered image data
    
    % basically store a class object for each of the types
    % start off with 
    properties
        LabelObj
        ImObj
        
        % parts of the image interface that are required
        Channel
        Tag = 'Annotated Image'; % for now
%         NativeColour
        
        % This should be moved into the interface superclass
        DefaultDisplay = @AnnotatedDisplay2DnC;
    end
    properties (Dependent)
        SizeX
        SizeY
        NumZSlice
        PixelSize
    end
    methods
        function this = cAnnotatedImage(varargin)
            % to begin with, replace each property with the new input,
            % rather than appending it..
            
            for ii = 1:numel(varargin)
                if isa(varargin{ii},'cImageInterface')
                    this.ImObj = varargin{ii};
                elseif isa(varargin{ii},'cLabelInterface')
                    this.LabelObj = varargin{ii};
                else
                    error('Invalid input')
                end
            end
            
            % this would be better using a get method
            this.Channel = this.ImObj.Channel;
            
            if isa(this.ImObj,'cImage3D') || isa(this.ImObj,'cImage3DnC')
                this.DefaultDisplay = @AnnotatedDisplay3DnC;
            end
        end
    end
    
    
    methods % cPixelDataInterface implementation
        function varargout = defaultDisplayObject(this,varargin)
            % this will gradually be phased out
            
            [dispObj,azfig] = this.getDisplayObject([],varargin{:});
            
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = azfig;
                end
            end
            
        end
        
        function varargout = getDisplayObject(this,classhandle,panelh,conObj,info)
            newFig = false;
            if nargin<3 || isempty(panelh)
                newFig = true;
                panelh = gfigure('Name','ImageView'); % not always going to be used in the explorer
            end
            linkContrast = false;
            
            
            
            % Following the approach of the display object, the type of
            % contrast adjustment could be specified by a class attribute
            % But leave this until there are more cases where 16bit isn't
            % appropriate
            if nargin<4 || isempty(conObj)
                % if no contrast adjuster supplied, then create one, and
                % then also create the manager which listens for contrast
                % changes and puts a menu on the figure
                conObj = ContrastAdjust16bit(this.ImObj.NumChannel);
                
                linkContrast = true;
            end
            
            
            
            
            if nargin<4
                info = [];
            end
            if nargin<2 || isempty(classhandle)
                classhandle = this.DefaultDisplay;
            end
            
            dispObj = classhandle(panelh,conObj,info);
            
            if linkContrast || newFig
                azfig = AZDisplayFig(panelh,dispObj,conObj);
            else
                azfig = [];
            end
            
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = azfig;
                end
            end
            
        end
        
        function n = getNumChannel(this)
            n = this.ImObj.NumChannel + this.LabelObj.NumChannel;
        end
        
        % Return a version of the image ready for display in a 2D viewer
        % these methods need to refer to the image data only, and have
        % different methods for accessing the label overlay (it's unlikely,
        % but not impossible that we'll want the label data as pixels for
        % the overlay, probably need additional methods for this)
        
        % IMPORTANT
        % Probably the best way to deal with this is to have image-specific
        % methods for images and label specific methods for labels, and the
        % cAnnotatedImage implements both.  For compatibility, the cLabel
        % will then implement the image methods but point them straight to
        % the label ones.  Not sure if there's any need for the image to
        % implement label methods.
        
        function im = getData2D(this)
            im = this.ImObj.getData2D();
            
        end
        function im = getData3D(this)
            im = this.ImObj.getData3D();
        end
        
        function im = getDataC2D(this)
            
            im = this.ImObj.getDataC2D();
        end
        function im = getDataC3D(this)
            
            im = this.ImObj.getDataC3D();
        end
        function im = rawdata(this,varargin)
            im = this.ImObj.rawdata(varargin{:});
        end
        
        function bxy = getOutline2D(this,varargin)
            bxy = getOutline2D(this.LabelObj,varargin{:});
        end
        
        function pHandles = showAnnotation(this,cmaps,parenth)
            % in this case, simply pass the call straight to the contained
            % label object
            pHandles = this.LabelObj.showAnnotation(cmaps,parenth);
        end
        
        function varargout = showImage(this,classhandle)
            % this is exactly the same as cImage2D, but I don't know how
            % easily the code for the two can be put in a single place
            % A Pixel2D class perhaps? Depends on if there are enough
            % common functions
            
            if nargin<2
                classhandle = [];
            end
            
            dispObj = getDisplayObject(this,classhandle);
            outputh = showImage(dispObj,this);
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = outputh;
                end
            end
            
        end
        
        function cval = getNativeColour(this,ind)
            % get it from the Image, but only if the index is within the
            % channel range
            % This is for compatibility with the image display classes
            numimchan = this.ImObj.getNumChannel();
            if ind<=numimchan
                cval = this.ImObj.getNativeColour(ind);
            else
                cval = this.LabelObj.getNativeColour(ind - numimchan);
            end
        end
        
        function val = get.SizeX(this)
            val = this.ImObj.SizeX;
        end
        function val = get.SizeY(this)
            val = this.ImObj.SizeY;
        end
        function val = get.NumZSlice(this)
            val = this.ImObj.NumZSlice;
        end
        function val = get.PixelSize(this)
            val = this.ImObj.PixelSize;
        end
        
    end
end