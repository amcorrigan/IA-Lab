classdef cBasicMultiChannelDisplay2D < cDisplayInterface
    properties
        ParentHandle % the handle of the containing graphics object
        AxHandle
        ImgHandle = [];
        
        MainVBox
        HideButton
        DispToolArray = {};
        
        
        % placeholder for being able to pass information (axes limits,
        % colourmap, etc) from an existing display
        % it's not been used yet, but I think it should be part of the
        % interface (passed in the constructor) for future functionality
        setupInfo = [];
        
        ImObj
        
        ConObj
        
        ColourMaps = {}
        
        BuiltInMaps = {[1,0,0],[0,1,0],[0,0,1],jet(256),parula(256),'custom'};
        
        CurrMap % the current selection for each channel
        
        ChannelShowCheckBoxes
        
        % standard row of colour choices that will be built in to each channel
        
%         ContrastLstnr % listener for contrast adjustment
        % it might make sense to move the listener outside of the display
        % into FigureDisplayList, so that only one event is triggered for
        % all the displays
        % then requires a manager class, which can be created by the
        % display if one isn't supplied.
    end
    methods
        function this = cBasicMultiChannelDisplay2D(parenth,contrastObj,info)
            % further down the line it might be possible to get the
            % contrast object from the parent handle (ie if it's a
            % FigureDisplayList, get the contrast from that and also find
            % the appropriate parent handle).  This will make it slightly
            % more consistent when calling separate from the GUI
            
            % This will be useful for listening for auto-limit setting -
            % only require this once, not once for every display, so MUST
            % come from FigureDisplayList.  Therefore, need one option for
            % parenth is FigureDisplayList, one option for not, and one for
            % create from scratch
            
            this.ParentHandle = parenth;
            
            if nargin<2 || isempty(contrastObj)
                % create a contrast adjustment object which can be brought
                % up - need to know how many channels there are..  This has
                % to be checked when showing an image
                this.ConObj = ContrastAdjust(0,parenth);
                
                % need to add a callback to the figure menu
            else
                this.ConObj = contrastObj;
            end
            
            % listening for constrast is now done by a managing class
%             this.ContrastLstnr = addlistener(this.ConObj,'settingsUpdate',@this.refreshImage);
            
            if nargin>2 && ~isempty(info)
                this.setupInfo = info;
            end
        end
        
        function varargout = showImage(this,imObj)
            
            if nargin>1
                this.ImObj = imObj;
                
            end
            
            if isempty(this.ColourMaps) && ~isempty(this.ImObj)
                % populate the default colourmap with the image objects
                % native colour
                this.ColourMaps = cell(this.ImObj.NumChannel,1);
                for ii = 1:numel(this.ColourMaps)
                    this.ColourMaps{ii} = [this.ImObj.getNativeColour(ii),this.BuiltInMaps(:)'];
                    this.CurrMap(ii) = ii + 1; % don't use native colour just yet, haven't extracted from parser.
                end
            end
            if ~isempty(this.ImObj)
                
                if isempty(this.AxHandle)
                    setupDisplay(this);
                end
                if ~isempty(this.ImgHandle)
                    delete(this.ImgHandle)
                end

                % cdata = uint16(imObj.getRGB2D()); % currently double to provide automatic scaling?
                
                % the contrast adjustment is likely to return a double anyway
                % for consistency.
                cdata = calculateImage(this);

                this.ImgHandle = imagesc('parent',this.AxHandle,'cdata',cdata);
                
                % only do this if it hasn't been done already?
                if strcmpi(get(this.AxHandle,'XLimMode'),'auto')
                    set(this.AxHandle,'xlim',[0,this.ImObj.SizeY],'ylim',[0,this.ImObj.SizeX])
                end
            else
                this.ImgHandle = NaN;
            end
            
            if nargout>0
                varargout{1} = this.ImgHandle;
            end
            
        end
        
        function cdata = calculateImage(this)
            % data is returned as cell array of double, which should be
            % fine for contrast adjustment
            pdata = process(this.ConObj,this.ImObj.getDataC2D()); % getRGB2D already converts to double
            
            % then need to build the RGB display based on which channels
            % are visible
            cdata = zeros(size(pdata{1},1),size(pdata{1},2),3,'uint8');
            
            for ii = 1:numel(this.ColourMaps)
                if get(this.ChannelShowCheckBoxes(ii),'value')
                    useMap = this.ColourMaps{ii}{this.CurrMap(ii)};
                    if size(useMap,1)==1
                        % single colour, don't need to call ind2rgb
                        if nnz(useMap)==1
                            % only r g or b is used, might be able to speed
                            % up further
                            col = find(useMap);
                            cdata(:,:,col) = max(cdata(:,:,col),uint8(255*useMap(col)*pdata{ii}));
                        else
                            cdata = max(cdata,uint8(bsxfun(@times,255*pdata{ii},reshape(useMap,[1,1,3]))));
                        end
                    else
                        % colormap
                        try
                            % converting to uint8 twice just to use ind2rgb
                            % is very unsatisfactory
                            cdata = max(cdata,uint8(255*ind2rgb(uint8(255*pdata{ii}),useMap)));
                        catch ME
                            rethrow(ME)
                        end
                        
                    end
                end
            end
        end
        
        function setupDisplay(this)
            this.MainVBox = uix.VBox('parent',this.ParentHandle);
                    
            this.AxHandle = axes('parent',this.MainVBox,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal');

            temp = uix.HBox('parent',this.MainVBox);
            this.HideButton = uicontrol('Style','pushbutton','parent',temp,'callback',...
                @this.toggleHide,'String',char(9660));
            
            
            for jj = 1:numel(this.ColourMaps)
                this.DispToolArray{jj} = uix.HBox('parent',this.MainVBox);
                for ii = 1:numel(this.ColourMaps{jj})
                    if ischar(this.ColourMaps{jj}{ii})
%                         tempcdata = rand(24,24,3); % for now
                        tempcdata = sliceref(rand(6,6,3),ceil((1:24)/4),ceil((1:24)/4)); % for now
                        str = 'C';
                    else
                        tempcdata = repmat(permute(resize3(this.ColourMaps{jj}{ii},[24,3]),[1,3,2]),[1,24,1]);
                        str = '';
                    end
                    try
                    uicontrol('parent',this.DispToolArray{jj},...
                      'style','pushbutton',...
                      'units','pix',...
                      'cdata', tempcdata, ...
                      'string', str,...
                      'Callback', {@this.colourCallback,jj,ii});
                    catch ME
                        rethrow(ME)
                    end
                end
                this.ChannelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj},'style','checkbox',...
                    'string',sprintf('Channel %d',jj),'Value',true,'callback',@(src,evt)this.showImage());
            
                uix.Empty('parent',this.DispToolArray{jj});
                try
                set(this.DispToolArray{jj},'widths',[24*ones(1,numel(this.ColourMaps{jj})),80,-1]);
                catch ME
                    rethrow(ME)
                end
                
            end
            set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ColourMaps))]);

        end
        
        function toggleHide(this,src,evt)
            if isempty(get(this.DispToolArray{1},'parent'))
                % needs to be reattached
                for ii = 1:numel(this.DispToolArray)
                    set(this.DispToolArray{ii},'parent',this.MainVBox)
                end
                set(this.HideButton,'string',char(9660))
                set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ColourMaps))]);
            else
                % needs to be removed
                for ii = 1:numel(this.DispToolArray)
                    set(this.DispToolArray{ii},'parent',[])
                end
                set(this.HideButton,'string',char(9650))
                set(this.MainVBox,'heights',[-1,12]);
            end
        end
        
        function colourCallback(this,src,evt,ch,ind)
            % this callback will be different from the single channel case,
            % because the images have to be merged.
            
            % Depending on the speed, it might be worth keeping a copy of
            % the contrast-adjusted data in the class..
            
            if ind==numel(this.ColourMaps{ch})
                % custom colour
                this.ColourMaps{ch}{ind} = uisetcolor('Choose a new colour');
                set(src,'cdata',bsxfun(@times,ones(24,24),reshape(this.ColourMaps{ch}{ind},[1,1,3])));
            end
            this.CurrMap(ch) = ind;
            
            if ishandle(this.ImgHandle)
                cdata = calculateImage(this);
                set(this.ImgHandle,'cdata',cdata);
            end
            
        end
        
        function imObj = getImObj(this)
            % seems trivial, but required for other viewers
            imObj = this.ImObj;
        end
        
        function cdata = getThumbnail(this,siz)
            if nargin<2 || isempty(siz)
                siz = 50;
            end
            if isempty(this.ImgHandle)
                cdata = NaN*ones(siz);
            else
                % how slow is this?
                cdata = imresize(get(this.ImgHandle,'cdata'),[siz,siz]);
            end
        end
        
        
        
        function gh = getSnapshotHandle(this)
            gh = this.AxHandle;
        end
        % doesn't use class instance - could be static
        function bool = isCompatible(this,imObj)
            % list of types of image for which this display is appropriate
            bool = isa(imObj,'cImage2D') || isa(imObj,'cImage3D') ...
                || isa(imObj,'cImageC2D') || isa(imObj,'cImageC3D');
        end
    end
end
