classdef cImage3D < cImageInterface & matlab.mixin.SetGet
    
    % 2D specialization of the cImage interface
    
    properties (Dependent)
        SizeX
        SizeY
        ImSize
    end
    properties (SetAccess = protected)
        NumChannel = 1;
        ImData % standard MATLAB array storing the pixel data
        
        FlagReadDone = [];
        
        ImInfo1
        
        NativeColour
        Channel = 1;
        
        PixelSize = [1,1,1];
        
        NumZSlice
        
        FileNames
        FilePath = '';
        
        Cancelling = false;
    end
    properties
        
        Tag = '3D image';
        
    end
    methods
        % cImage2D is the only one that doesn't separate filepath from
        % filename, simply because there is only one file!
        function this = cImage3D(iFileNames,iFilePath,iColour,chan,pixsize,tag,iImData,iFlagDone)
            % additional input is the image data itself, which might have
            % been read in already before creation
            
            % ought to check the types of these inputs
            if nargin>0 && ~isempty(iFileNames)
                this.FileNames = iFileNames;
                
            end
            if nargin>1 && ~isempty(iFilePath)
                this.FilePath = iFilePath;
            end
            if nargin>2 && ~isempty(iColour)
                this.NativeColour = iColour;
            end
            
            this.NumZSlice = numel(this.FileNames);
            
            if nargin>3 && ~isempty(chan)
                this.Channel = chan; % need to know this for global processing within YE
                % otherwise it's not used, so doesn't really matter too
                % much
            end
            if nargin>4 && ~isempty(pixsize)
                this.PixelSize = pixsize;
            end
            
            if nargin>5 && ~isempty(tag)
                this.Tag = tag;
            end
            
            if nargin>6 && ~isempty(iImData)
                this.ImData = iImData;
                
                % probably want to check that the image size matches the
                % information for the filename we've been given, but do
                % that later
                
                this.FlagReadDone = iFlagDone;
            end
            
            if isempty(this.FlagReadDone)
                this.FlagReadDone = false(this.NumZSlice,1);
            end
        end
    end
    methods % image interface methods
        function data = rawdata(this,~,z)
            % first check if the data has been read in
            
            if nargin<2 || isempty(z)
                tempz = 1:this.NumZSlice;
            else
                tempz = z;
            end
            
            toBeRead = nnz(~this.FlagReadDone(tempz));
            
            showbar = false;
            if toBeRead>0
                showbar = true;
                progressBarAPI('setstyle',@SpinProgCancel)
                progressBarAPI('init','Reading Images',toBeRead);
                cancelhandle = progressBarAPI('getcancelhandle');
                if ~isempty(cancelhandle)
                    templstn = addlistener(progressBarAPI('getcancelhandle'),'cancel',@this.triggerCancel);
                end
            end
            
            for ii = 1:numel(tempz)
                if ~this.FlagReadDone(tempz(ii))
                    getSingleSlice_(this,tempz(ii));
                    if showbar
                        if this.Cancelling
                            % the cancel has been 
                            this.Cancelling = false;
                            error('IA:Cancel','Cancelled by user')
                        end
                        progressBarAPI('increment');
                    end
                end
            end
            
            data = this.ImData(:,:,tempz);
            
            if showbar
                progressBarAPI('finish');
                progressBarAPI('setstyle',@SpinProgMsgBar)
                if ~isempty(cancelhandle)
                    delete(templstn)
                end
                drawnow();
            end
        end
         function varargout = showImage(this,conObj)
             if nargin<2
                conObj = [];
            end
            [dispObj,conObj] = defaultDisplayObject(this,[],conObj);
            showImage(dispObj,this);
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = conObj;
                end
            end
        end
        
        % This doesn't require an instance - could be static?
        function [dispObj,conObj,azfig] = defaultDisplayObject(this,panelh,conObj,info)
            if nargin<2 || isempty(panelh)
                panelh = gfigure('Name','ImageView'); % not always going to be used in the explorer
            end
            linkContrast = false;
            if nargin<3 || isempty(conObj)
                % if no contrast adjuster supplied, then create one, and
                % then also create the manager which listens for contrast
                % changes and puts a menu on the figure
                conObj = ContrastAdjust16bit(this.NumChannel);
                
                linkContrast = true;
            end
            if nargin<4
                info = [];
            end
            
%             dispObj = BasicDisplay3DnC(panelh,conObj,info);
            dispObj = Display3DnC(panelh,conObj,info);
            
            if linkContrast
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
            im = max(rawdata(this),[],3);
            
        end
        function im = getData3D(this)
            im = rawdata(this);
        end
        
        function im = getDataC2D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = {max(rawdata(this),[],3)};
        end
        function im = getDataC3D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = {rawdata(this)};
        end
        
    end
    methods % 3D specific
        function varargout = getSingleSlice_(this,zind)
            % internal function for reading image files into the ImData
            % property
            if this.FlagReadDone(zind)
                im = this.ImData(:,:,zind);
            else
                im = imread(fullfile(this.FilePath,this.FileNames{zind}));
                
                if isempty(this.ImData)
                    % the z-stack hasn't been initialized yet
                    this.ImData = zeros(this.SizeX,this.SizeY,this.NumZSlice,'uint16');
                end
                this.ImData(:,:,zind) = im;
                this.FlagReadDone(zind) = true;
            end
            
            if nargout>0
                varargout{1} = im;
            end
            
        end
        
    end
    methods % Housekeeping
        function cval = getNativeColour(this,ind)
            % ignore the ind if it has been supplied
            cval = this.NativeColour;
        end
        
        function oSize = get.ImSize(this) % return the dimensionality of the image, including all dimensions
            info = retrieveimInfo1(this);
            
            oSize = [info.Height,info.Width,max(this.NumZSlice),this.numChannel];
        end
        
        function oSizeX = get.SizeX(this)
            info = retrieveimInfo1(this);
            oSizeX = info.Height;
        end
        function oSizeY = get.SizeY(this)
            info = retrieveimInfo1(this);
            oSizeY = info.Width;
        end
        
        function oNumZSlice = getNumZSlice(this)
            
            
            oNumZSlice = this.NumZSlice;
            
        end
        
        
        function ndim = getNDim(this) % get the number of dimensions (XYZCT)
            ndim = 2 + double(this.NumZSlice>1);
        end
        
        function info = retrieveimInfo1(this)
            % this will usually be a private method, but no guarantee yet..
            if isempty(this.ImInfo1)
                this.ImInfo1 = imfinfo(fullfile(this.FilePath,this.FileNames{1}));
            end
            info = this.ImInfo1;
        end
    end
end