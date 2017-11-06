classdef cImage2D < cImageInterface & matlab.mixin.SetGet
    
    % 2D specialization of the cImage interface
    
    properties (Dependent)
        SizeX
        SizeY
        ImSize
    end
    properties (SetAccess = protected)
        NumChannel = 1;
        
        ImData % standard MATLAB array storing the pixel data
        
        FlagReadDone = false;
        
        ImInfo1
        
        Channel = 1; % default, overwritten in constructo integer index - need to know this so that any existing contrast
        % adjustment will know which adjustment to apply
        
        NativeColour = [1,1,1];
        
        PixelSize = [1,1];
        
        FileName
    end
    properties
        Tag = '2D image'; % description of the image which is shown in the title bar
        % have as cell array, called by getTag
        % then we can specify whether we want a short tag or the full tag
        % For now, it's just a string
    end
    methods % Constructor
        % cImage2D is the only one that doesn't separate filepath from
        % filename, simply because there is only one file!
        function this = cImage2D(iFileName,iColour,chan,pixsize,tag,iImData)
            % additional input is the image data itself, which might have
            % been read in already before creation
            
            % ought to check the types of these inputs
            if nargin>0 && ~isempty(iFileName)
                this.FileName = iFileName;
                
            end
            if nargin>1 && ~isempty(iColour)
                if iscell(iColour)
                    iColour = iColour{1};
                end
                this.NativeColour = iColour;
            end
            
            if nargin>2 && ~isempty(chan)
                this.Channel = chan; % need to know this for global processing within YE
                % otherwise it's not used, so doesn't really matter too
                % much
            end
            
            if nargin>3 && ~isempty(pixsize)
                this.PixelSize = pixsize;
            end
            
            if nargin>4 && ~isempty(tag)
                this.Tag = tag;
            end
            
            if nargin>5 && ~isempty(iImData)
                this.ImData = iImData;
                
                % probably want to check that the image size matches the
                % information for the filename we've been given, but do
                % that later
                
                this.FlagReadDone = true;
            end
        end
    end %--Constructor
    
    methods % Image interface methods
        
        function data = rawdata(this,~,~)
            % first check if the data has been read in
            if isempty(this.ImData)
                this.ImData = imread(this.FileName);
                this.FlagReadDone = true;
            end
            data = this.ImData;
        end
        
        % This doesn't require an instance - could be static?
        function [dispObj,conObj,azfig] = defaultDisplayObject(this,panelh,conObj,info)
            newFig = false;
            if nargin<2 || isempty(panelh)
                newFig = true;
                panelh = gfigure('Name','ImageView'); % not always going to be used in the explorer
            end
            linkContrast = false;
            if nargin<3 || isempty(conObj)
                % if no contrast adjuster supplied, then create one, and
                % then also create the manager which listens for contrast
                % changes and puts a menu on the figure
                if nargin>0 && ~isempty(this)
                    ch = this.Channel;
                else
                    ch = 1;
                end
                
                conObj = ContrastAdjust16bit(1,[],[],[],ch);
                
                linkContrast = true;
            end
            if nargin<4
                info = [];
            end
%             dispObj = cDisplay2DCMap(panelh,info);
%             dispObj = cBasicDisplay2D(panelh,conObj,info);
            dispObj = Display2DnC(panelh,conObj,info);
            
            if linkContrast || newFig
                azfig = AZDisplayFig(panelh,dispObj,conObj);
            else
                azfig = [];
            end
        end
        
        
        function n = getNumChannel(this)
            n = 1;
        end
        
        % Return a version of the image ready for display in a 2D viewer
        function im = getData2D(this)
            % in this case, it's simply the raw data, but this method still
            % needs to be here for use by viewing classes!
            im = rawdata(this);
            
        end
        function im = getData3D(this)
            im = rawdata(this);
        end
        
        function im = getDataC2D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = {rawdata(this)};
        end
        function im = getDataC3D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = {rawdata(this)};
        end
        
        function varargout = showImage(this,conObj)
            if nargin<2
                conObj = [];
            end
            [dispObj,conObj] = defaultDisplayObject(this,[],conObj);
            outputh = showImage(dispObj,this);
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = conObj;
                end
            end
        end
        
    end %-- interface
    
    methods % GENERAL - MIGHT BE ABLE TO MOVE THESE TO THE SUPERCLASS not quite!
        % there are small differences between single channel and
        % multichannel
        function cval = getNativeColour(this,ind)
            % ignore the ind if it has been supplied
            cval = this.NativeColour;
        end
        
        function oSizeX = get.SizeX(this)
            % need to check that there is a file before doing this!
            info = retrieveimInfo1(this);
            oSizeX = info.Height;
        end
        function oSizeY = get.SizeY(this)
            % need to check that there is a file before doing this!
            info = retrieveimInfo1(this);
            oSizeY = info.Width;
        end
        function oSize = get.ImSize(this) % return the dimensionality of the image, including all dimensions
            info = retrieveimInfo1(this);
            
            oSize = [info.Height,info.Width,1,this.numChannel];
        end
        
        
        
        function ndim = getNDim(this) % get the number of dimensions (XYZCT)
            ndim = 2;
        end
        
        function info = retrieveimInfo1(this)
            % this will usually be a private method, but no guarantee yet..
            if isempty(this.ImInfo1)
                this.ImInfo1 = imfinfo(this.FileName);
            end
            info = this.ImInfo1;
        end
        
    end %--General methods
end