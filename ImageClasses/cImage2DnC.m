classdef cImage2DnC < cImageInterface & matlab.mixin.SetGet
    
    % 2D specialization of the cImage interface
    
    properties (Dependent)
        SizeX
        SizeY
        ImSize
        
    end
    properties (SetAccess = protected)
        NumChannel
        ImData % standard MATLAB array storing the pixel data
        
        FlagReadDone = [];
        
        ImInfo1
        
        Channel % integer index - need to know this so that any existing contrast
        % adjustment will know which adjustment to apply
        
        NativeColour
        PixelSize = [1,1];
        
        FileNames
        FilePath
    end
    properties
        Tag = '2D&C image'
    end
    methods % Constructor
        % cImage2D is the only one that doesn't separate filepath from
        % filename, simply because there is only one file!
        function this = cImage2DnC(iFileNames,iFilePath,iColour,chan,pixsize,tag,iImData)
            % additional input is the image data itself, which might have
            % been read in already before creation
            
            % ought to check the types of these inputs
            if nargin>0 && ~isempty(iFileNames)
                this.FileNames = iFileNames;
            end
            
            if nargin>1 && ~isempty(iFilePath)
                this.FilePath = iFilePath;
            end
            
            if nargin>5 && ~isempty(tag)
                this.Tag = tag;
            end
            
            if nargin>6 && ~isempty(iImData)
                this.ImData = iImData;
                
                % probably want to check that the image size matches the
                % information for the filename we've been given, but do
                % that later
                
                this.FlagReadDone = ~cellfun(@isempty,this.ImData);
                this.NumChannel = numel(this.ImData);
                
                % make sure the iminfo is populated for when we come
                % looking for it
                if isempty(this.FileNames)
                    this.ImInfo1 = struct('Height',size(this.ImData{1},1),...
                        'Width',size(this.ImData{1},2));
                end
                
            else
                this.ImData = cell(this.NumChannel,1);
                this.NumChannel = numel(this.FileNames);
                this.FlagReadDone = false(this.NumChannel,1);
            end
            
            if nargin<4 || isempty(chan)
                chan = 1:this.NumChannel; % this is fine for now
            end
            this.Channel = chan;
            
            if nargin<3 || isempty(iColour)
                iColour = repmat({[1,1,1]},[this.NumChannel,1]);
            end
            this.NativeColour = iColour;
            if ~iscell(this.NativeColour)
                this.NativeColour = num2cell(this.NativeColour,2);
            end
            
            if nargin>4 && ~isempty(pixsize)
                this.PixelSize = pixsize;
            end
            
            
        end
    end % Constructor
    methods % Image interface methods
        
        function flipData(this)
            for i = 1:this.NumChannel
                this.ImData{i} = flipud(this.ImData{i});
            end;
        end
        
        function oImData = rawdata(this,c,~)
            % first check if the data has been read in
            if nargin<2
                % all channels
                c = 1:this.NumChannel;
            end
            
            % don't think we should be making a copy, just make sure
            % everything is read in and then return the ImData
            oImData = cell(numel(c),1);
            for ii = 1:numel(c)
                oImData{ii} = getSingleSlice_(this,c(ii));
            end
        end
        
        function [dispObj,conObj,azfig] = defaultDisplayObject(this,panelh,conObj,info)
            newscroll = false;
            
            if nargin<2 || isempty(panelh)
                panelh = gfigure('Name','ImageView'); % not always going to be used in the explorer
                newscroll = true;
            end
%             linkContrast = false;
            if nargin<3 || isempty(conObj)
                % if no contrast adjuster supplied, then create one, and
                % then also create the manager which listens for contrast
                % changes and puts a menu on the figure
                conObj = ContrastAdjust16bit(this.NumChannel,[],[],[],this.Channel);
                
%                 linkContrast = true;
            end
            if nargin<4
                info = [];
            end
%             dispObj = cDisplay2DCMap(panelh,info);
%             dispObj = cBasicMultiChannelDisplay2D(panelh,conObj,info);
            dispObj = Display2DnC(panelh,conObj,info);
            
            if newscroll
                azfig = AZDisplayFig(panelh,dispObj,conObj);
            else
                azfig = [];
            end
        end
        
        
        function n = getNumChannel(this)
            n = this.NumChannel;
        end
        
        % Return a version of the image ready for display in a 2D viewer
        function im = getData2D(this)
            % in this case, it's simply the raw data, but this method still
            % needs to be here for use by viewing classes!
            error('Not implemented flattening of multichannel image yet')
            % probably max value at each pixel is the best way to go
            
        end
        function im = getData3D(this)
            error('Not implemented flattening of multichannel image yet')
            % probably max value at each pixel is the best way to go
        end
        
        function im = getDataC2D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = rawdata(this);
        end
        function im = getDataC3D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = rawdata(this);
        end
        
        function varargout = showImage(this, conObj)
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
    methods % 2DnC specific
        function imObj = getImage2D(this,cind,~)
            % return a cImage2D object which will then be able to handle
            % displays
            
            % At this point, shouldn't matter whether the slice has been
            % read in or not
            
            if this.FlagReadDone(cind)
                imObj = cImage2D(fullfile(this.FilePath,this.FileNames{cind}),...
                    this.NativeColour{cind},cind,this.ImData{cind});
            else
                imObj = cImage2D(fullfile(this.FilePath,this.FileNames{cind}),...
                    this.NativeColour{cind},cind);
            end
        end
        function imObj = getImageC2D(this,~)
            % return the image object - this is required for compatibility
            % with more complex image classes
            % ignore the input, which is required for classes with
            % z-slices
            imObj = this;
        end
        
        function varargout = getSingleSlice_(this,cind)
            % internal function for reading image files into the ImData
            % property
            if this.FlagReadDone(cind)
                im = this.ImData{cind};
            else
                im = imread(fullfile(this.FilePath,this.FileNames{cind}));
                
                this.FlagReadDone(cind) = true;
                
                this.ImData{cind} = im;
            end
            
            if nargout>0
                varargout{1} = im;
            end
            
        end
        
        function cdata = getThumbnail(this)
            % choose a slice from each channel to display
            % read in as little as possible
            cdata = zeros(50,50,3);
            for ii = 1:this.NumChannel
                if this.FlagReadDone(ii)
                    temp = imresize(this.ImData{ii},[50,50]);
                    
                else
                    impath = fullfile(this.FilePath,this.FileNames{ii});
                    temp = imresize(...
                        imread(impath,'PixelRegion', {[1 20 this.SizeX],[1 20 this.SizeY]}),...
                        [50,50]);
                end
                try
                col = reshape(this.NativeColour{ii},[1,1,3]);
                catch me
                    rethrow(me)
                end
                cdata = max(cdata, bsxfun(@times,col,rangeNormalise(temp)));
            end
        end
        
    end %-- 2DnC specific
    methods % General housekeeping - part of interface?
        
        function cval = getNativeColour(this,ind)
            
            cval = this.NativeColour(ind);
        end
        
        function oSizeX = get.SizeX(this)
            info = retrieveimInfo1(this);
            oSizeX = info.Height;
        end
        function oSizeY = get.SizeY(this)
            info = retrieveimInfo1(this);
            oSizeY = info.Width;
        end
        
        function oSize = get.ImSize(this) % return the dimensionality of the image, including all dimensions
            info = retrieveimInfo1(this);
            
            oSize = [info.Height,info.Width,this.NumChannel];
        end
        
        
        function ndim = getNDim(this) % get the number of dimensions (XYZCT)
            ndim = 2 + double(this.numChannel)>1;
        end
        
        function info = retrieveimInfo1(this)
            % this will usually be a private method, but no guarantee yet..
            if isempty(this.ImInfo1)
                this.ImInfo1 = imfinfo(fullfile(this.FilePath,this.FileNames{1}));
            end
            info = this.ImInfo1;
        end
        
    end

    methods (Static)
        function imObj = trueColour(file,tag,pixsize)
            if nargin<3 || isempty(pixsize)
                pixsize = [1,1];
            end
            
            % read the file, separate the channels and then send to the cImage2DnC class
            rgb = imread(file);
            
            % need to make sure that the type is uint16 for now - it would be better if
            % the contrast object was autogenerated depending on the image type
            
            % because of this issue, save the implementation of this until after the
            % deployment of the v2 viewer?
            if isa(rgb,'double')
                rgb = uint16(65536*rgb);
            elseif isa(rgb,'uint8')
                rgb = 256.0*uint16(rgb);
            end
            
            temp = cell(3, 1);
            temp{1} = rgb(:, :, 1);
            temp{2} = rgb(:, :, 2);
            temp{3} = rgb(:, :, 3);
            
% %             imObj = cImage2DnC([],[],{[1,0,0];[0,1,0];[0,0,1]},1:3,...
% %                pixsize,tag,num2cell(rgb,[1,2]));
            
            imObj = cImage2DnC([],[],{[1,0,0];[0,1,0];[0,0,1]},1:3,...
                               pixsize,tag,temp);
        end
    end
end