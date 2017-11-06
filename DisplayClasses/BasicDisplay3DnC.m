classdef BasicDisplay3DnC < cDisplayInterface
    % Current standard for 2D multichannel displays
    %
    % There will be other options at some point, but this meant to be the
    % default for most use cases.

    properties
        ParentHandle % the handle of the containing graphics object

        FigParent % Useful to store a direct reference to the parent figure, for handling callbacks
        AxHandle
        ImgHandle = [];

        MainVBox
        HideButton
        DispToolArray = {};
        ToolHBox


        % placeholder for being able to pass information (axes limits,
        % colourmap, etc) from an existing display
        % it's not been used yet, but I think it should be part of the
        % interface (passed in the constructor) for future functionality
        setupInfo = [];

        ImObj
        ImData % test of keeping the cell array of pixels stored for easy access
               % hopefully it will be stored as a reference to the ImObj
               % values and so won't take extra memory?

        ConObj

        CxtMenu

        ColourMaps = {}

%         BuiltInMaps = {[1,0,0],[0,1,0],[0,0,1],'custom'};

        BuiltInMaps = {...
                        [1 0.1094 0],...
                        [0 1 0.6328],...
                        [0 0.1875 1],...
                        [1 0.6367 0],...
                        'custom'};


        CurrMap % the current selection for each channel
        UseMaps % store the current contrast adjusted maps, and only recalculate when required

        ChannelShowCheckBoxes

        hSP=[];
        hOvPanel = [];

        PrevMousePosition
        
        CurrSlice
        NumZSlice
        
        SliderZ
        SliderText
        ScrollMode = 1;

        % standard row of colour choices that will be built in to each channel

%         ContrastLstnr % listener for contrast adjustment
        % it might make sense to move the listener outside of the display
        % into DisplayManager, so that only one event is triggered for
        % all the displays
        % then requires a manager class, which can be created by the
        % display if one isn't supplied.
    end
    methods
        function this = BasicDisplay3DnC(parenth,contrastObj,info)
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

            this.ParentHandle = parenth;
            aHandle = this.ParentHandle;
            while isa(aHandle, 'matlab.ui.Figure') == 0
                aHandle = aHandle.Parent;
            end
            this.FigParent = aHandle;

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

            %%  Context menu (right click)
            %-- If the current parent uiControl is NOT a figure, go ask its parent

            this.CxtMenu = uicontextmenu(this.FigParent);
            uimenu(this.CxtMenu,'label','Zoom in', 'CallBack', {@this.contextcallback, 'Zoom in'});
            uimenu(this.CxtMenu,'label','Zoom out', 'CallBack', {@this.contextcallback, 'Zoom out'});
            uimenu(this.CxtMenu,'label','Fit the window', 'CallBack', {@this.contextcallback, 'Fit the window'});
            uimenu(this.CxtMenu,'label','Close Tab', 'CallBack', {@this.contextcallback, 'Close Tab'},...
                         'separator', 'on');
            uimenu(this.CxtMenu,'label','Close All', 'CallBack', {@this.contextcallback, 'Close All'});


        end

        function varargout = showImage(this,imObj)

            % This also gets called when the contrast is changed.
            % putting a new image over the top disrupts the imoverview
            % panel, so need to destroy/disable it and hten bring it back.

            if nargin>1
                this.ImObj = imObj;
                this.ImData = this.ImObj.getDataC3D();
            end

            if isempty(this.ColourMaps) && ~isempty(this.ImObj)
                % populate the default colourmap with the image objects
                % native colour
                this.ColourMaps = cell(this.ImObj.NumChannel,1);

                % this is where the current maps will be stored - empty
                % means recalculate
                this.UseMaps = cell(this.ImObj.NumChannel,1);

                for ii = 1:numel(this.ColourMaps)
                    this.ColourMaps{ii} = [this.ImObj.getNativeColour(ii),this.BuiltInMaps(:)'];
                    this.CurrMap(ii) = 1; % use native colour.
                end
            end
            if ~isempty(this.ImObj)

                if isempty(this.AxHandle)
                    setupDisplay(this);
                end

                % cdata = uint16(imObj.getRGB2D()); % currently double to provide automatic scaling?

                % the contrast adjustment is likely to return a double anyway
                % for consistency.
                cdata = this.calculateImage;

                if isempty(this.hSP)
                    this.ImgHandle = imagesc('parent',this.AxHandle,'cdata',cdata);


                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%________________________________________________
                    %%  Scroll Panel for panning
                    this.hSP = imscrollpanel(this.AxHandle.Parent, this.ImgHandle);

                    set(this.hSP, 'Units','normalized','Position',[0 0 1 1]);
                    set(this.hSP.Children(2),'BackgroundColor',[0 0 0]);
                    set(this.hSP.Children(3),'BackgroundColor',[0 0 0]);

                    api = iptgetapi(this.hSP);
                    api.setMagnification(api.findFitMag());
% %                 end
                    %%________________________________________________
                    set(this.FigParent,'WindowKeyPressFcn',@this.keypressfun)


                    this.ImgHandle.UIContextMenu = this.CxtMenu;
                    this.hSP.UIContextMenu = this.CxtMenu;

                    this.hOvPanel = imoverviewpanel(this.AxHandle.Parent, this.ImgHandle);

                    set(this.hOvPanel,'Units','Normalized', 'Position',[0.85 0.85 0.15 0.15],...
                        'BackgroundColor', [1 1 1], 'BorderType', 'beveledin', 'BorderWidth', 3);

                    %%________________________________________________
                    %%  Magnification info
                    immagbox(this.AxHandle.Parent, this.ImgHandle);


                    % this should be registered to the manager rather than being set
                    % directly
%                     set(aHandle,'WindowScrollWheelFcn',@this.scrollfun)

                    api.setImageButtonDownFcn(@this.buttondownfun)

                else
                    api = iptgetapi(this.hSP);
                    api.replaceImage(cdata,'PreserveView',true);
                end

                %-- This may take a long time to run.
%                 drawnow();


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
            %-- maybe save the pdata as artributes.
            %-- To do: how to invert colour

            % rewritten so that it's the colourmap that has the contrast
            % adjustment applied, rather than the image..
            
%             imdata = this.ImObj.getDataC3D(); % we should ensure that this method returns a uint16 array
            
            if isempty(this.CurrSlice)
                this.NumZSlice = size(this.ImData{1},3);
                this.CurrSlice = ceil(this.NumZSlice/2);
                set(this.SliderZ,'min',1,'max',this.NumZSlice,'value',this.CurrSlice,...
                    'callback',@this.slidercallback)
            end
            
            cdata = zeros(size(this.ImData{1},1)*size(this.ImData{1},2),3,'uint8');
            % start off with a column vector, one row per pixel and reshape
            % at the end

            % for some reason, the DPC image is a different size!
            % check for that here, and calculate the region of the image
            % that should be displayed
            imsizes = cell2mat(cellfun(@(x)[size(x,1),size(x,2)],this.ImData,'uni',false));

            % value to start at
            lowerval = 1 + floor(bsxfun(@minus,imsizes,min(imsizes,[],1))/2);

            % value to end at
            upperval = imsizes - ceil(bsxfun(@minus,imsizes,min(imsizes,[],1))/2);


            for ii = 1:numel(this.ColourMaps) % number of channels
                if get(this.ChannelShowCheckBoxes(ii),'value')
                  if isempty(this.UseMaps{ii})
                    tempMap = this.ColourMaps{ii}{this.CurrMap(ii)};
                    if size(tempMap,1)==1
                        % get it working first, then look for speed
                        % improvements
                        tempMap = uint8(255*createcmap([0,0,0;tempMap],256));
                    end

                    % apply contrast adjustment to the colourmap
                    testind = uint8(this.ConObj.getLUT(this.ImObj.Channel(ii))*255);
                    this.UseMaps{ii} = tempMap(testind+1,:);
                  end
                  
                  try
                  temp = this.ImData{ii}(lowerval(ii,1):upperval(ii,1),lowerval(ii,2):upperval(ii,2),this.CurrSlice);
                  catch ME
                      rethrow(ME)
                  end
                  
                  try
                  cdata = max(cdata,this.UseMaps{ii}(temp(:)+1,:));
                  catch ME
                    rethrow(ME)
                  end
                end
            end

            cdata = reshape(cdata,[size(this.ImData{1},1),size(this.ImData{1},2),3]);

        end

        function scrollfun(this,src,evt)
            
            if this.ScrollMode~=0
                % use mouse scrolling to adjust the zoom in small increments
                zoomfact = 1.2^(-evt.VerticalScrollCount); % 20% zoom for each scroll

                api = iptgetapi(this.hSP);
                api.setMagnification(api.getMagnification() * zoomfact);
            else
                % it's the z-slice that we want to increment
                
                this.CurrSlice = max(1,min(this.NumZSlice,this.CurrSlice - evt.VerticalScrollCount));
                
                % only the XY panel needs updating
                cdata = calculateImage(this);
%                 set(this.ImgHandle,'cdata',cdata);
                api = iptgetapi(this.hSP);
                api.replaceImage(cdata,'PreserveView',true);
                
                % update the slider
                set(this.SliderZ,'value',this.CurrSlice);
                set(this.SliderText,'string',sprintf('Z=%d',this.CurrSlice))
            end

        end
        
        function slidercallback(this,src,evt)
            this.CurrSlice = round(get(src,'Value'));
            set(src,'value',this.CurrSlice)
            
            cdata = calculateImage(this);
%             set(this.ImgHandle,'cdata',cdata);
            api = iptgetapi(this.hSP);
            api.replaceImage(cdata,'PreserveView',true);
            
            set(this.SliderText,'string',sprintf('Z=%d',this.CurrSlice))
        end

        function funhand = getScrollFun(this)
            % hopefully this works as expected.
            funhand = @this.scrollfun;
        end

        function buttondownfun(this,src,evt)
            % the basic idea is that when the button is pressed, we
            % register a new windowbuttonmotionfcn to control the panning,
            % and a new windowbuttonupfcn that will remove these two
%             IAHelp();

            % change the mouse cursor to the pan style and set up the
            % callbacks for movement.
            set(this.FigParent,'Pointer','fleur',...
                'WindowButtonMotionFcn',@this.cursormovefun,...
                'WindowButtonUpFcn',@this.buttonupfun)

            % record the current cursor location in order to calculate
            % movement
            this.PrevMousePosition = get(this.FigParent,'CurrentPoint');

        end

        function cursormovefun(this,src,evt)
            currpos = get(this.FigParent,'CurrentPoint');

            % calculate the distance moved
            delta = [1,-1].*(this.PrevMousePosition - currpos);

            this.PrevMousePosition = currpos;

            % then need to set the window view accordingly
            api = iptgetapi(this.hSP);


            % delta needs scaling by the current magnification

            newLoc = api.getVisibleLocation() + delta/api.getMagnification();

            api.setVisibleLocation(newLoc);


        end

        function buttonupfun(this,src,evt)
            set(this.FigParent','WindowButtonMotionFcn','',...
                'WindowButtonUpFcn','','Pointer','arrow');
        end
        
        function keypressfun(this,src,evt)
            % check if the key is ctrl, and if so, change the scroll mode
            if ~isempty(evt.Character) || isempty(evt.Modifier)
                return
            end
            if numel(evt.Modifier)==1 && strcmpi(evt.Modifier{1},'control')
                this.ScrollMode = 0;
                set(this.FigParent,'WindowKeyReleaseFcn',@this.keyreleasefun)
            end
            
            
        end
        
        function keyreleasefun(this,src,evt)
            this.ScrollMode = 1;
            set(this.FigParent,'WindowKeyReleaseFcn','')
        end
        
        function setupDisplay(this)
            this.MainVBox = uix.VBox('parent',this.ParentHandle);

            hPanel = uipanel('Parent', this.MainVBox, 'units','normalized');
            set(hPanel,'Position',[0 0 1 1]);

            this.AxHandle = axes('parent',hPanel,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal');
            axis(this.AxHandle,'ij');


            temp = uix.HBox('parent',this.MainVBox);
            this.HideButton = uicontrol('Style','pushbutton','parent',temp,'callback',...
                @this.toggleHide,'String',char(9660));


            this.ToolHBox = uix.HBox('parent',this.MainVBox);
            vbox1 = uix.VBox('parent',this.ToolHBox,'Spacing', 5);
            gbox2 = uix.Grid('parent',this.ToolHBox);

            set(this.ToolHBox,'widths',[-1,-1]);


            for jj = 1:numel(this.ColourMaps)



                this.DispToolArray{jj} = uix.HBox('parent',vbox1);


                this.ChannelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj},'style','checkbox',...
                                                           'string',sprintf('Channel %d',jj),'Value',true,'callback',@(src,evt)this.showImage());


                uicontrol('parent',this.DispToolArray{jj},...
                          'style','pushbutton',...
                          'units','pix',...
                          'foregroundColor', this.ColourMaps{jj}{1}, ...
                          'backgroundColor', [0 0 0], ...
                          'string', 'D',...
                          'FontWeight', 'bold',...
                          'FontSize', 16,...
                          'Callback', {@this.colourCallback,jj,1});


                for ii = 2:numel(this.ColourMaps{jj})
                    if ischar(this.ColourMaps{jj}{ii})

                        uicontrol('parent',this.DispToolArray{jj},...
                                  'style','pushbutton',...
                                  'units','pix',...
                                  'backgroundColor', [0 0 0], ...
                                  'foregroundColor', [1 1 1], ...
                                  'string', '...',...
                                  'FontSize', 16,...
                                  'FontWeight', 'bold',...
                                  'Callback', {@this.colourCallback,jj,ii});

                    else
                        uicontrol('parent',this.DispToolArray{jj},...
                                  'style','pushbutton',...
                                  'units','pix',...
                                  'backgroundColor', this.ColourMaps{jj}{ii}, ...
                                  'Callback', {@this.colourCallback,jj,ii});
                    end
                end

                uix.Empty('parent',this.DispToolArray{jj});
                try
                    set(this.DispToolArray{jj},'widths',[80,24*ones(1,numel(this.ColourMaps{jj})),-1]);
                catch ME
                    rethrow(ME)
                end

            end
            
            this.SliderZ = uicontrol('style','slider','parent',gbox2);
            this.SliderText = uicontrol('style','text','string',sprintf('Z=%d',this.CurrSlice),'parent',gbox2);
            
            set(gbox2,'widths',[-5,-1],'heights',60,'spacing',10);

            set(this.MainVBox,'heights',[-1,12,24*numel(this.ColourMaps)]);

        end

        function toggleHide(this,src,evt)
            if isempty(get(this.ToolHBox,'parent'))
                % needs to be reattached
                set(this.ToolHBox,'parent',this.MainVBox)

                set(this.HideButton,'string',char(9660))
                set(this.MainVBox,'heights',[-1,12,24*numel(this.ColourMaps)]);
            else
                % needs to be removed
                set(this.ToolHBox,'parent',[])
                
                set(this.HideButton,'string',char(9650))
                set(this.MainVBox,'heights',[-1,12]);
            end
        end

        function colourCallback(this,src,evt,ch,ind)
            % this callback will be different from the single channel case,
            % because the images have to be merged.

            % Depending on the speed, it might be worth keeping a copy of
            % the contrast-adjusted data in the class..


            % flag the chosen coloumap for recalculation
            % this happens when the contrast or colour of the channel is changed.
            try
            this.UseMaps{ch} = [];
            catch ME
                rethrow(ME)
            end
            
            if ~isempty(src)
                if ind==numel(this.ColourMaps{ch})
                    % custom colour
                    this.ColourMaps{ch}{ind} = uisetcolor('Choose a new colour');
                    set(src,'backgroundColor',this.ColourMaps{ch}{ind});
                    set(src,'foregroundColor',1-this.ColourMaps{ch}{ind});
                end
                this.CurrMap(ch) = ind;

                if ishandle(this.ImgHandle)
                    cdata = calculateImage(this);
                    try
    % %                 set(this.ImgHandle,'cdata',cdata);
                        api = iptgetapi(this.hSP);
                        api.replaceImage(cdata,'PreserveView',true);
                    catch ME
                        rethrow(ME)
                    end
                end
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

        function contextcallback(this,src,evt,label)
            % could numbers be used for these instead of labels?
            switch label
                case 'Zoom in'
                    api = iptgetapi(this.hSP);
                    mag = api.getMagnification();
                    api.setMagnification(mag * 2);
                case 'Zoom out'
                    api = iptgetapi(this.hSP);
                    mag = api.getMagnification();
                    api.setMagnification(mag * 0.5);
                case 'Fit the window'
                    api = iptgetapi(this.hSP);
                    api.setMagnification(api.findFitMag());
                case 'Close Tab'
                    data = GenEvtData(1);
                    notify(this,'closeRequest',data)
                case 'Close All'
                    data = GenEvtData('all');
                    notify(this,'closeRequest',data)
            end
        end
    end
end
