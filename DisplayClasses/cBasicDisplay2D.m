classdef cBasicDisplay2D < cDisplayInterface
    % In this version, we want to use the supplied NativeColour information
    % from the image object
    
    % for most 
    
    properties
        ParentHandle % the handle of the containing graphics object
        AxHandle
        ImgHandle = [];
        
        % down the line there will be the possibility of setting the
        % colourmap and all that...
        
        
        % placeholder for being able to pass information (axes limits,
        % colourmap, etc) from an existing display
        % it's not been used yet, but I think it should be part of the
        % interface (passed in the constructor) for future functionality
        setupInfo = [];
        
        ImObj
        
        ConObj
        
        ColourMaps = {}
        
        BuiltInMaps = {[1,0,0],[0,1,0],[0,0,1],jet(256),parula(256),'custom'};
        
%         CurrMap
        
        CurrType = '';
        
        % add custom choice at some point
        
%         ContrastLstnr % listener for contrast adjustment
        % it might make sense to move the listener outside of the display
        % into DisplayManager, so that only one event is triggered for
        % all the displays
        % then requires a manager class, which can be created by the
        % display if one isn't supplied.
    end
    methods
        function this = cBasicDisplay2D(parenth,contrastObj,info)
            % further down the line it might be possible to get the
            % contrast object from the parent handle (ie if it's a
            % DisplayManager, get the contrast from that and also find
            % the appropriate parent handle).  This will make it slightly
            % more consistent when calling separate from the GUI
            
            % This will be useful for listening for auto-limit setting -
            % only require this once, not once for every display, so MUST
            % come from DisplayManager.  Therefore, need one option for
            % parenth is DisplayManager, one option for not, and one for
            % create from scratch
            
            % also want to allow no contrast adjustment to be imposed, by
            % passing NaN as the constrast object
            
            if nargin<1 || isempty(parenth)
                parenth = gfigure('Name','ImageView');
            end
            
            this.ParentHandle = parenth;
            
            if nargin<2 || isempty(contrastObj)
                % create a contrast adjustment object which can be brought
                % up - need to know how many channels there are..  This has
                % to be checked when showing an image
                this.ConObj = ContrastAdjust(1,parenth);
                
                % need to add a callback to the figure menu
            else
                this.ConObj = contrastObj;
            end
            
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
                if isa(this.ImObj,'cLabelInterface')
                    this.CurrType = 'label';
                    this.ColourMaps = [{this.ImObj.getNativeColour},this.BuiltInMaps(:)'];
                    for ii = 1:numel(this.ColourMaps)
                        % go through each colour map and adjust it for best
                        % display of label arrays
                        
                        % if it's a colour map, put the zero colour at the
                        % very start.
                        % start off by defaulting to black for everything
                        if size(this.ColourMaps{ii},1)>1
                            this.ColourMaps{ii} = [0,0,0;this.ColourMaps{ii}];
                        end
                        
                        % if it's a solid colour, it'll be sorted out in
                        % the colourcallback function
                    end
                else
                    this.CurrType = 'image';
                    this.ColourMaps = [{this.ImObj.getNativeColour},this.BuiltInMaps(:)'];
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
                
                if isa(this.ConObj,'ContrastAdjust')
                    cdata = chanProcess(this.ConObj,this.ImObj.getData2D(),this.ImObj.Channel); % getRGB2D already converts to double
                else
                    cdata = this.ImObj.getData2D();
                end
                % the contrast adjustment is likely to return a double anyway
                % for consistency.

                this.ImgHandle = imagesc('parent',this.AxHandle,'cdata',cdata);
                set(this.AxHandle,'xlim',[0,this.ImObj.SizeY],'ylim',[0,this.ImObj.SizeX],...
                    'clim',[0,1])
                % set to the first colourmap, which should be NativeColour
                colourCallback(this,[],[],1);
            else
                this.ImgHandle = NaN;
            end
            
            
            if nargout>0
                varargout{1} = this.ImgHandle;
            end
            
        end
        
        function setupDisplay(this)
            tempvbox = uix.VBox('parent',this.ParentHandle);
                    
            this.AxHandle = axes('parent',tempvbox,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal');

            temphbox = uix.HBox('parent',tempvbox);

            for ii = 1:numel(this.ColourMaps)
                if ischar(this.ColourMaps{ii})
                    tempcdata = rand(24,24,3); % for now
                    str = 'C';
                else
                    tempcdata = repmat(permute(amcResize3D(this.ColourMaps{ii},[24,3]),[1,3,2]),[1,24,1]);
                    str = '';
                end
                uicontrol('parent',temphbox,...
                  'style','pushbutton',...
                  'units','pix',...
                  'cdata', tempcdata, ...
                  'string', str,...
                  'Callback', {@this.colourCallback,ii});
            end
            uix.Empty('parent',temphbox);

            set(temphbox,'widths',[24*ones(1,numel(this.ColourMaps)),-1]);
            set(tempvbox,'heights',[-1,24]);

        end
        
        function colourCallback(this,src,evt,ind)
            if ind==numel(this.ColourMaps)
                % custom colour
                colour = uisetcolor('Choose a new colour');
            else
                colour = this.ColourMaps{ind};
            end
            
            if size(colour,1)==1
                if strcmpi(this.CurrType,'label')
                    % start the colour from partway up
                    colour = [0;linspace(0.25,1,255)'] * colour;
                else
                    colour = linspace(0,1,256)' * colour;
                end
            end
            
            colormap(this.AxHandle,colour)
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
        
        function imObj = getImObj(this)
            % seems trivial, but required for other viewers
            imObj = this.ImObj;
        end
        
        % doesn't use class instance - could be static
        function bool = isCompatible(this,imObj)
            % list of types of image for which this display is appropriate
% %             bool = isa(imObj,'cImage2D') || isa(imObj,'cImage3D') ...
% %                 || isa(imObj,'cImageC2D') || isa(imObj,'cImageC3D');
                bool = true; % until we find an image type that can't be displayed.
        end
        
        function gh = getSnapshotHandle(this)
            gh = this.AxHandle;
        end
    end
end
