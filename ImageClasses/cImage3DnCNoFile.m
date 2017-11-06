classdef cImage3DnCNoFile < cImage3DnC
    % version of the 4D image class which isn't based on image files
    %
    % The constructor and any methods which use the filenames need to be
    % overridden
    properties
        
    end
    methods
        function this = cImage3DnCNoFile(imData, iColour, chan, pixsize,tag)
            this.ImData = imData(:);
            this.NumChannel = numel(this.ImData);
            
            if nargin<4 || isempty(chan)
                chan = 1:this.NumChannel; % this is fine for now
            end
            this.Channel = chan;
            
            this.NumZSlice = zeros(this.NumChannel,1);
            this.flagReadDone = cell(this.NumChannel,1);
            
            if nargin<3 || isempty(chan)
                chan = 1:this.NumChannel; % this is fine for now
            end
            this.Channel = chan;
            
            for ii = 1:this.NumChannel
                this.NumZSlice(ii) = size(this.ImData{ii},3);
                this.flagReadDone{ii} = true(this.NumZSlice(ii),1);
            end
            this.flagAllDone = true;
            
            if nargin>3 && ~isempty(pixsize)
                this.PixelSize = pixsize;
            end
            if nargin>4 && ~isempty(tag)
                this.Tag = tag;
            else
                this.Tag = '3D&C image';
            end
            
            this.imInfo1 = struct('Height',size(this.ImData{1},1),'Width',size(this.ImData{1},2));
            
            if nargin>1 && ~isempty(iColour)
                this.NativeColour = iColour;
                if ~iscell(this.NativeColour)
                    this.NativeColour = num2cell(this.NativeColour,2);
                end
            else
                this.NativeColour = repmat({[1,1,1]},[this.NumChannel,1]);
            end
        end
        
        function info = retrieveimInfo1(this)
            % this will usually be a private method, but no guarantee yet..
            info = this.imInfo1;
        end
        
        function imdata = rawdata(this,c,z)
            % may as well override this to save some of the checks on the
            % file reading
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
            
            
            if getAll
                imdata = this.ImData;
                return
            end
            
            if isempty(z)
                imdata = this.ImData{c};
                return
            end
                
            imdata = cell(numel(c),1);
            for ii = 1:numel(c)
                if isempty(z)
                    zrange = 1:size(this.ImData{c(ii)},3);
                else
                    zrange = z;
                    zrange(zrange>size(this.ImData{c(ii)},3)) = [];
                end
                imdata{ii} = this.ImData{c(ii)}(:,:,zrange);
            end
            
        end
        
        function varargout = getSingleSlice_(this,cind,zind)
            if cind>this.NumChannel || zind>this.NumZSlice(cind)
                im = [];
            else
                im = this.ImData{cind}(:,:,zind);
            end
            
            if nargout>0
                varargout{1} = im;
            end
        end
        
    end
end