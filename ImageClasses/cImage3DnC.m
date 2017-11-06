classdef cImage3DnC < cImageInterface % & matlab.mixin.SetGet
    %-- This class is for 3D stack + colour channel
    %
    %
    % Image class based around individual files for individual slices, ie
    % suitable for 2D, 3D and 4D images
    % 
    % First question - should cImage be a handle?
    % My (AMC) guess would be yes, so that different images can be passed
    % around (in multi-channel arrays) without making multiple copies of
    % the pixel data.
    % But this does mean that care will have to be taken when doing image
    % processing to ensure that the raw data isn't accidentally modified
    
    properties (Dependent)
        SizeX
        SizeY
        ImSize
    end
    
    properties (SetAccess = protected)
        ImData % cell array of numeric arrays, containing the data for each channel
        
        filePath = ''; % optional parent directory to put at the start of each file
        fileNames % cell array of cell arrays of strings
        
        flagReadDone;       %-- if a file has been read in, a boolean flag (cell array of vectors)
        
        % NOT CURRENTLY USED
        flagAllDone = false;%-- if all the above flag is true or not. 
        
        NumChannel
        
        NumZSlice
        
        imInfo1 = []; % information from the first file in the list, used for getting meta information
    
        NativeColour = [];
        PixelSize = [1,1,1];
        Channel
        
        Cancelling = false;
    end
    properties
        
        Tag = '3D&C image';
        
    end
    
    methods % Constructor
        function this = cImage3DnC(iFileNames, iFilePath, iColour,chan,pixsize,tag)
            if nargin==0
                % for when sub-classes want a different construction syntax
                return
            end
            if nargin>1 && ~isempty(iFilePath)
                this.filePath = iFilePath;
            end
            this.fileNames = iFileNames;
            
            this.NumChannel = numel(this.fileNames);
            
            this.NumZSlice = zeros(this.NumChannel,1);
            this.flagReadDone = cell(this.NumChannel,1);
            
            if nargin<4 || isempty(chan)
                chan = 1:this.NumChannel; % this is fine for now
            end
            this.Channel = chan;
            
            for ii = 1:this.NumChannel
                this.NumZSlice(ii) = numel(this.fileNames{ii});
                this.flagReadDone{ii} = false(this.NumZSlice(ii),1);
            end
            
            
            if nargin>4 && ~isempty(pixsize)
                this.PixelSize = pixsize;
            end
            
            if nargin>5 && ~isempty(tag)
                this.Tag = tag;
            end
            
            this.ImData = cell(this.NumChannel,1);
            
            if nargin>2 && ~isempty(iColour)
                this.NativeColour = iColour;
            else
                this.NativeColour = repmat({[1,1,1]},[this.NumChannel,1]);
            end
        end
    end % Constructor
    methods % interface
        
        function oImData = rawdata(this,c,z)
            % TO DO - remove c and z and make sure it's always all of
            % them..
            
            getAll = false;
            if nargin<3
                z = [];
                getAll = true;
            end
            if nargin<2
                % all channels
                c = 1:this.NumChannel;
            else
                getAll = false;
            end
            
            % some sort of progress would be useful
            toBeRead = 0;
            for ii = 1:numel(c)
                if isempty(z)
                    tempz = 1:this.NumZSlice(c(ii));
                else
                    tempz = z;
                end
                toBeRead = toBeRead + nnz(~this.flagReadDone{c(ii)}(tempz));
            end
            
%             wb = GenTimer('Reading Images',toBeRead,0,AZProgObj());
            showbar = false;
            if toBeRead>0
%                 wb = AZTimer('Reading Images',toBeRead);
                showbar = true;
                progressBarAPI('setstyle',@SpinProgCancel)
                progressBarAPI('init','Reading Images',toBeRead);
                cancelhandle = progressBarAPI('getcancelhandle');
                if ~isempty(cancelhandle)
                    templstn = addlistener(progressBarAPI('getcancelhandle'),'cancel',@this.triggerCancel);
                end
            end
            
            if ~getAll
                oImData = cell(numel(c),1);
            end
            for ii = 1:numel(c)
                try
                if isempty(z)
                    tempz = 1:this.NumZSlice(c(ii));
                else
                    tempz = z;
                end
                catch ME
                    rethrow(ME)
                end
                
                
%                 oImData{ii} = zeros(this.SizeX,this.SizeY,numel(tempz),'uint16');
                % rather than filling oImData from the function, try
                % populating ImData then getting directly from that
                % This tries to avoid making a copy of the data until it is
                % modified.
                for jj = 1:numel(tempz)
% %                     if ~getAll
% %                         oImData{ii}(:,:,jj) = getSingleSlice_(this,c(ii),tempz(jj));
% %                     end

                    % only call this if necessary
                    if ~this.flagReadDone{c(ii)}(tempz(jj))
                        getSingleSlice_(this,c(ii),tempz(jj));
                    
                        if showbar
    %                         wb.increment();
                            if this.Cancelling
                                % the cancel has been 
                                this.Cancelling = false;
                                error('IA:Cancel','Cancelled by user')
                            end
                            progressBarAPI('increment');
                        end
                    end
                end
                
                if ~getAll
                    oImData{ii} = this.ImData{c(ii)}(:,:,tempz);
                end
            end
            
            if getAll
                oImData = this.ImData;
            end
            
            if showbar
%                 wb.finish();  
                progressBarAPI('finish');
                progressBarAPI('setstyle',@SpinProgMsgBar)
                if ~isempty(cancelhandle)
                    delete(templstn)
                end
                drawnow();
            end
        end
        
        function triggerCancel(this,src,evt)
            this.Cancelling = true;
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
        
        function [dispObj,conObj,azfig] = defaultDisplayObject(this,panelh,conObj,info)
            
            if nargin<2 || isempty(panelh)
                panelh = gfigure('Name','ImageView'); % not always going to be used in the explorer
            end
            linkContrast = false;
            if nargin<3 || isempty(conObj)
                % if no contrast adjuster supplied, then create one, and
                % then also create the manager which listens for contrast
                % changes and puts a menu on the figure
                conObj = ContrastAdjust16bit(this.NumChannel,[],[],[],this.Channel);
                
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
            n = this.NumChannel;
        end
        
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
            tempim = rawdata(this);
            im = cellfun(@(x)max(x,[],3),tempim,'UniformOutput',false);
        end
        function im = getDataC3D(this)
            % converted to double for now, but another option is to cast
            % the NativeColour to the same type as the image data..
            im = rawdata(this);
        end
        
        function clearImData(this)
            % remove ImData if it's not going to be used any more
            % not sure there's a proper need for this yet..
            warning('Not implemented pixel data deletion for saving memory yet')
        end
        
        function cdata = getThumbnail(this)
            % choose a slice from each channel to display
            % read in as little as possible
            cdata = zeros(50,50,3);
            for ii = 1:this.NumChannel
                zind = ceil(this.NumZSlice(ii)/2);
                if this.flagReadDone{ii}(zind)
                    temp = imresize(this.ImData{ii}(:,:,zind),[50,50]);
                    
                else
                    impath = fullfile(this.filePath,this.fileNames{ii}{zind});
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
        
    end
    methods % 3DnC specific
        function loadAll(this)
            % go through and make sure that everything is loaded up.  This
            % is useful for if separate channels will be sent off to
            % different segmentation methods, to avoid having to read them
            % in more than once.
            for ii = 1:this.NumChannel
                % this assumes that the channels start from 1
                for jj = 1:this.NumZSlice(ii)
                    getSingleSlice_(this,ii,jj);
                end
            end
        end
        
        function varargout = getSingleSlice_(this,cind,zind)
            % internal function for reading image files into the ImData
            % property
            if this.flagReadDone{cind}(zind)
                im = this.ImData{cind}(:,:,zind);
            else
                im = imread(fullfile(this.filePath,this.fileNames{cind}{zind}));
                
                if isempty(this.ImData{cind})
                    % the z-stack hasn't been initialized yet
                    this.ImData{cind} = zeros(this.SizeX,this.SizeY,this.NumZSlice(cind),'uint16');
                end
                
                this.ImData{cind}(1:size(im,1),1:size(im,2),zind) = im;
                
                this.flagReadDone{cind}(zind) = true;
            end
            
            if nargout>0
                varargout{1} = im;
            end
            
        end
    
        % Return a version of the image ready for display in a 2D viewer
        
        function imObj = getImage2D(this,cind,zind)
            % return a cImage2D object which will then be able to handle
            % displays
            
            % At this point, shouldn't matter whether the slice has been
            % read in or not
            
            % what should be done if the zslice is greater than the number
            % of slices available for that channel?
            % for now, just take the max available
            
            if cind>numel(this.flagReadDone)
                cind = numel(this.flagReadDone);
            end
            if zind>numel(this.flagReadDone{cind})
                zind = numel(this.flagReadDone{cind});
            end
            
            if this.flagReadDone{cind}(zind)
                imObj = cImage2D(fullfile(this.filePath,this.fileNames{cind}{zind}),...
                    this.NativeColour{cind},cind,this.PixelSize(1:2),this.Tag,...
                    this.ImData{cind}(:,:,zind));
            else
                imObj = cImage2D(fullfile(this.filePath,this.fileNames{cind}{zind}),...
                    this.NativeColour{cind},cind,this.PixelSize(1:2),this.Tag);
            end
        end
        
        function imObj = getImage3D(this,cind)
            % return a cImage2D object which will then be able to handle
            % displays
            
            % At this point, shouldn't matter whether the slice has been
            % read in or not
            
            imObj = cImage3D(this.fileNames{cind},this.filePath,this.NativeColour{cind},...
                cind,this.PixelSize,this.Tag,...
                    this.ImData{cind},this.flagReadDone{cind});
            
        end
        
        function imObj = getImageC2D(this,zind)
            % return a cImage2D object which will then be able to handle
            % displays
            
            % At this point, shouldn't matter whether the slice has been
            % read in or not
            
            % Need to explicitly construct the image data and whether it
            % has been read in
            tempData = cell(this.NumChannel,1);
            tempFiles = cell(this.NumChannel,1);
            
            for ii = 1:this.NumChannel
                tempFiles{ii} = this.fileNames{ii}{zind};
                if this.flagReadDone{ii}(zind)
                    tempData{ii} = this.ImData{ii}(:,:,zind);
                end % otherwise leave empty
            end
            
            imObj = cImage2DnC(tempFiles,this.filePath,this.NativeColour,this.Channel,...
                this.PixelSize(1:2),this.Tag,tempData);
            
        end
        
        function imObj = getProjC2D(this,projfun)
            
            if nargin<2 || isempty(projfun)
                projfun = 'max';
            end
            
            if ~isa(projfun,'function_handle')
                switch lower(projfun)
                    case 'mean'
                        projfun = @(x)mean(x,3);
                    otherwise
                        projfun = @(x)max(x,[],3);
                end
            end
            
            imdata = cellfun(projfun,this.getDataC3D(),'uni',false);
            imObj = cImage2DnC([],[],this.NativeColour,this.Channel,this.PixelSize(1:2),this.Tag,imdata);
        end
        
        function oImData = rawdata_select(this,c,z)
            % TO DO - this is deprecated and can be removed after testing
            % that the new rawdata is working as expected
            
            if nargin<3
                z = [];
            end
            if nargin<2
                % all channels
                c = 1:this.NumChannel;
            end
            
            % some sort of progress would be useful
            toBeRead = 0;
            for ii = 1:numel(c)
                if isempty(z)
                    tempz = 1:this.NumZSlice(c(ii));
                else
                    tempz = z;
                end
                toBeRead = toBeRead + nnz(~this.flagReadDone{c(ii)}(tempz));
            end
            
%             wb = GenTimer('Reading Images',toBeRead,0,AZProgObj());
            showbar = false;
            if toBeRead>2
%                 wb = AZTimer('Reading Images',toBeRead);
                showbar = true;
                progressBarAPI('setstyle',@SpinProgCancel)
                progressBarAPI('init','Reading Images',toBeRead);
                 templstn = addlistener(progressBarAPI('getcancelhandle'),'cancel',@this.triggerCancel);
            end
            
            oImData = cell(numel(c),1);
            for ii = 1:numel(c)
                try
                if isempty(z)
                    tempz = 1:this.NumZSlice(c(ii));
                else
                    tempz = z;
                end
                catch ME
                    rethrow(ME)
                end
                
                
%                 oImData{ii} = zeros(this.SizeX,this.SizeY,numel(tempz),'uint16');
                % rather than filling oImData from the function, try
                % populating ImData then getting directly from that
                % This tries to avoid making a copy of the data until it is
                % modified.
                for jj = 1:numel(tempz)
%                     oImData{ii}(:,:,jj) = getSingleSlice_(this,c(ii),tempz(jj));
                    getSingleSlice_(this,c(ii),tempz(jj));
                    if showbar
%                         wb.increment();
                        if this.Cancelling
                            % the cancel has been 
                            this.Cancelling = false;
                            error('IA:Cancel','Cancelled by user')
                        end
                        progressBarAPI('increment');
                    end
                end
                
                oImData{ii} = this.ImData{c(ii)}(:,:,tempz);
                
            end
            
            if showbar
%                 wb.finish();  
                progressBarAPI('finish');
                progressBarAPI('setstyle',@SpinProgMsgBar)
                delete(templstn)
            end
        end
        
    end % 
    
    methods % Housekeeping
        function cval = getNativeColour(this,ind)
            
            cval = this.NativeColour(ind);
        end
        
        function oSize = get.ImSize(this) % return the dimensionality of the image, including all dimensions
            info = retrieveimInfo1(this);
            
            oSize = [info.Height,info.Width,max(this.NumZSlice),this.NumChannel];
        end
        
        function oSizeX = get.SizeX(this)
            info = retrieveimInfo1(this);
            oSizeX = info.Height;
        end
        function oSizeY = get.SizeY(this)
            info = retrieveimInfo1(this);
            oSizeY = info.Width;
        end
        
        function oNumZSlice = getNumZSlice(this,channelIndex)
            if nargin<2 || isempty(channelIndex)
                channelIndex = 1:obj.NumChannel;
            end
            oNumZSlice = zeros(numel(channelIndex),1);
            for ii = 1:numel(channelIndex)
                oNumZSlice(ii) = numel(this.fileNames{channelIndex(ii)});
            end
        end
        
        
        function ndim = getNDim(this) % get the number of dimensions (XYZCT)
            ndim = 2 + double(this.NumChannel)>1 + double(any(this.NumZSlice>1));
        end
        
        function info = retrieveimInfo1(this)
            % this will usually be a private method, but no guarantee yet..
            if isempty(this.imInfo1)
                try
                this.imInfo1 = imfinfo(fullfile(this.filePath,this.fileNames{1}{1}));
                catch ME
                    rethrow(ME)
                end
            end
            info = this.imInfo1;
        end
        
    end % Housekeeping
    
end