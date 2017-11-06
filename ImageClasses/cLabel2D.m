classdef cLabel2D < cLabelInterface % use this class to define the interface before abstracting
    
    % Label matrix class for storing the result of segmentations
    % see RegionLabels for the previous attempt at this, which stored the
    % pixel lists rather than the label array itself
    
    % The next question is what should be stored with the labels, centroid?
    % regionprops outputs? Centroid might be useful for overloading plot
    % calls for example?
    
    properties (Dependent)
        SizeX
        SizeY
        ImSize
        CMap % default colour map when none is specified, like NativeColour for images
    end
    properties
        Name
        LData % basic label array
        NumLabels = 0;
        
        CMap_  % private cmap to stop MATLAB complaining about using other properties in the setting..
        NumChannel = 1;
        RPerm
    end
    
    methods
        % to begin with, just a wrapper for a label array, but down the
        % line there will be different variants - eg multi-'channel' would
        % be cells, nuclei, punctae, eg.
        function this = cLabel2D(L,cmap)
            % currently no check making sure it's only a 2D array that is
            % passed.
            if nargin>0 && ~isempty(L)
                this.LData = L;
                this.NumLabels = max(this.LData(:));
                this.RPerm = randperm(this.NumLabels)';
            end
            
            if nargin>1 && ~isempty(cmap)
                this.CMap = cmap;
            end
        end
        
        
        function set.CMap(this,cmap)
            % check that this gets called from the constructor
%             n = this.NumLabels;
%             if n==0
                n = 255;
%             end
            if ischar(cmap)
                % not sure if feval can be compiled?
                this.CMap_ = feval(cmap,n);
            end
            
        end
        
        function cmap = get.CMap(this)
            cmap = this.CMap_;
        end
        
        function val = get.SizeX(this)
            val = size(this.LData,1);
        end
        function val = get.SizeY(this)
            val = size(this.LData,2);
        end
        function val = get.ImSize(this)
            val = size(this.LData);
        end
        
        % then also need some show methods
        % Like for the image class, rather than impose the display here,
        % instead provide the output in the appropriate format
        function L = rawdata(this)
            L = this.LData;
        end
        
        function im = getData2D(this)
            % return the label matrix but shuffled.  How can we sort out
            % the background colour?
            
            vals = [0;this.RPerm]/this.NumLabels; % needs to go from 0 to 1
            im = vals(this.LData + 1);
        end
        
        function im = getData3D(this)
            im = getData2D(this);
        end
        
        
    end
    
    
    
    methods % cPixelDataInterface implementation
        function dispObj = defaultDisplayObject(~,panelh,~,dispInfo)
            % third input missing because contrast information isn't really
            % relevant for pure label matrix
            newFig = false;
            if nargin<2 || isempty(panelh)
                newFig = true;
                panelh = gfigure('Name','LabelView'); % not always going to be used in the explorer
            end
            
            if nargin<4
                info = [];
            end
            
            dispObj = cBasicDisplay2D(panelh,NaN,info);
            
            if newFig
                azfig = AZDisplayFig(panelh,dispObj,NaN);
            end
            
        end
        
        function varargout = showImage(this)
            % this is exactly the same as cImage2D, but I don't know how
            % easily the code for the two can be put in a single place
            % A Pixel2D class perhaps? Depends on if there are enough
            % common functions
            
            dispObj = defaultDisplayObject(this);
            outputh = showImage(dispObj,this);
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = outputh;
                end
            end
        end
        
        function cval = getNativeColour(this,ind)
            cval = this.CMap_;
        end
    end
    
    
    
    methods % Overloaded functions
        % Bear in mind that the underlying data is being changed, rather
        % than making a copy when no output is requested
        function varargout = imdilate(this,varargin)
            if nargout>0
                that = copy(this);
                that.LData = imdilate(that.LData,varargin{:});
                varargout{1} = that;
            else
                this.LData = imdilate(this.LData,varargin{:});
            end
            
        end
        function varargout = imerode(this,varargin)
            if nargout>0
                that = copy(this);
                that.LData = imerode(that.LData,varargin{:});
                varargout{1} = that;
            else
                this.LData = imerode(this.LData,varargin{:});
            end
            
        end
        
        function varargout = minus(this,that)
            if nargout>0
                theOther = copy(this);
                theOther.LData = this.LData - that.LData;
                varargout{1} = theOther;
            else
                this.LData = this.LData - that.LData;
            end
        end
        
        function himage = imshow(this,varargin)
            rgb = getDataRGB(this);
            himage = imshow(rgb,varargin{:});
        end
        function varargout = imtophat(this,varargin)
            if nargout>0
                that = copy(this);
                that.LData = imtophat(that.LData,varargin{:});
                varargout{1} = that;
            else
                this.LData = imtophat(this.LData,varargin{:});
            end
            
        end
    end
end
