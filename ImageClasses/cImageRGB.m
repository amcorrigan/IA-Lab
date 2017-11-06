classdef cImageRGB < cImageInterface & matlab.mixin.SetGet
%-- the classical RGB image class, M*N*3    
    
    properties (Dependent)
        SizeX
        SizeY
        ImSize
        
    end
    properties (SetAccess = protected)
        NumChannel = 3;
        ImData = [];
        
        FlagReadDone = [];
        
        Channel = 1:1:3;% integer index - need to know this so that any existing contrast
        
        PixelSize = [1,1];
        
        FileName
        FilePath
    end
    properties
        Tag = 'RGB image'
    end
    methods % Constructor
        
        function this = cImageRGB(iFilePath, iFileName, pixsize, tag, iImData)
            
            if nargin>0 && ~isempty(iFilePath)
                this.FilePath = iFilePath;
            end
            
            if nargin>1 && ~isempty(iFileName)
                this.FileName = iFileName;
            end
            
            if nargin>3 && ~isempty(tag)
                this.Tag = tag;
            end
            
            if nargin>4 && ~isempty(iImData)
                this.ImData = iImData;
            else
                this.ImData = imread(fullfile(this.FilePath, this.FileName));
            end
            
            if nargin>4 && ~isempty(pixsize)
                this.PixelSize = pixsize;
            end
        end
    end % Constructor
    
    methods % Image interface methods
        
        function flipData(this)
            for i = 1:this.NumChannel
                this.ImData = flipud(this.ImData);
            end;
        end
        
        function oImData = rawdata(this)
            oImData = this.getImage2D();
        end
        
        function dispObj = defaultDisplayObject(this, panelh, ~, ~)
            
            dispObj = DisplayRGB(panelh);
        end
        
        function n = getNumChannel(this)
            n = this.NumChannel;
        end
       
        function im = getDataC2D(this)
            if isempty(this.ImData)
                im = imread(fullfile(this.FilePath,this.FileName));
            else
                im = this.ImData;
            end;
        end
        
        function varargout = showImage(this)
            dispObj = this.defaultDisplayObject();
            
            if nargout>0
                varargout{1} = dispObj;
            end
        end
    end %-- interface

    methods
        function oSizeX = get.SizeX(this)
            info = imfinfo(fullfile(this.FilePath,this.FileName));
            oSizeX = info.Height;
        end
        function oSizeY = get.SizeY(this)
            info = imfinfo(fullfile(this.FilePath,this.FileName));
            oSizeY = info.Width;
        end
        
        function oSize = get.ImSize(this) % return the dimensionality of the image, including all dimensions
            info = imfinfo(fullfile(this.FilePath,this.FileName));
            oSize = [info.Height,info.Width,info.NumberOfSamples];
        end
    end
end