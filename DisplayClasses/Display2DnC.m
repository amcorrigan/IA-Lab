classdef Display2DnC < cDisplayInterface
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
        
        % placeholder for being able to pass information (axes limits,
        % colourmap, etc) from an existing display
        % it's not been used yet, but I think it should be part of the
        % interface (passed in the constructor) for future functionality
        setupInfo = [];

        ImObj

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
        
        ScaleBarInfo = ScaleBarHelper('thickness',5,'pixelsize',200);
        ScaleHandle
        ScaleText
        
        ChannelLabels

        % standard row of colour choices that will be built in to each channel

%         ContrastLstnr % listener for contrast adjustment
        % it might make sense to move the listener outside of the display
        % into DisplayManager, so that only one event is triggered for
        % all the displays
        % then requires a manager class, which can be created by the
        % display if one isn't supplied.
    end
    methods
        function this = Display2DnC(parenth,contrastObj,info)
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
            
            temphandle = uimenu(this.CxtMenu,'label','Scale bar','separator','on');
            uimenu(temphandle,'label','Show/refresh','callback',{@this.scalebarcallback,'refresh'})
            uimenu(temphandle,'label','Hide','callback',{@this.scalebarcallback,'hide'})
            uimenu(temphandle,'label','Cycle position','callback',{@this.scalebarcallback,'poscycle'})
            
            

        end
        
        function addChannelLabels(this,chanLabels)
            % keep this separate from the constructor for now
            this.ChannelLabels = chanLabels;
        end
        
        function varargout = showImage(this,imObj)

            % This also gets called when the contrast is changed.
            % putting a new image over the top disrupts the imoverview
            % panel, so need to destroy/disable it and hten bring it back.

            if nargin>1
                this.ImObj = imObj;

            end

            if isempty(this.ColourMaps) && ~isempty(this.ImObj)
                this.populateColourmaps()
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
        
        function populateColourmaps(this)
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
        
        function cdata = calculateImage(this)
            % data is returned as cell array of double, which should be
            % fine for contrast adjustment
            %-- maybe save the pdata as artributes.
            %-- To do: how to invert colour

            % rewritten so that it's the colourmap that has the contrast
            % adjustment applied, rather than the image..
            % This is almost fast enough without storing the individual
            % channels, but it could be done so that the individual
            % testmaps are stored and then marked as dirty if they need to
            % be recalculated, eg by colourcallback

            imdata = this.ImObj.getDataC2D(); % we should ensure that this method returns a uint16 array
            
            try
            cdata = zeros(size(imdata{1},1)*size(imdata{1},2),3,'uint8');
            % start off with a column vector, one row per pixel and reshape
            % at the end
            catch me
                rethrow(me)
            end
            % for some reason, the DPC image is a different size!
            % check for that here, and calculate the region of the image
            % that should be displayed
            imsizes = cell2mat(cellfun(@(x)[size(x,1),size(x,2)],imdata,'uni',false));

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
%                         tempMap = uint8(255*createcmap([0,0,0;tempMap],256));
                        tempMap = uint8(255*colorGradient([0,0,0],tempMap,256));
                    end

                    % apply contrast adjustment to the colourmap
                    try
                        aChannel = this.ImObj.Channel(ii);
                        testind = uint8(this.ConObj.getLUT(aChannel)*255);
                    catch me
                        rethrow(me);                     
                    end
                    
                    this.UseMaps{ii} = tempMap(testind+1,:);
                  end
                  temp = imdata{ii}(lowerval(ii,1):upperval(ii,1),lowerval(ii,2):upperval(ii,2));
                  cdata = max(cdata,this.UseMaps{ii}(temp(:)+1,:));

                end
            end

            cdata = reshape(cdata,[size(imdata{1},1),size(imdata{1},2),3]);

        end

        function scrollfun(this,src,evt)
            % use mouse scrolling to adjust the zoom in small increments
            zoomfact = 1.2^(-evt.VerticalScrollCount); % 20% zoom for each scroll

            api = iptgetapi(this.hSP);
            newmag = api.getMagnification() * zoomfact;
            % round to the nearest percentage point, if we're at a high
            % enough magnification to do this
            if newmag>0.1
                newmag = round(100*newmag)/100;
            end
            api.setMagnification(newmag);
            
            if ~isempty(this.ScaleHandle)
                this.scalebarcallback([],[],'refresh')
            end

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
            
            if ~isempty(this.ScaleHandle)
                this.scalebarcallback([],[],'refresh')
            end

        end

        function buttonupfun(this,src,evt)
            set(this.FigParent','WindowButtonMotionFcn','',...
                'WindowButtonUpFcn','','Pointer','arrow');
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


            if isempty(this.ChannelLabels)
                % if we haven't supplied labels for the channels, create
                % default ones here
                numChan = numel(this.ColourMaps);
                this.ChannelLabels = arrayfun(@num2str,(1:numChan)','uni',false);
            end

            for jj = 1:numel(this.ColourMaps)



                this.DispToolArray{jj} = uix.HBox('parent',this.MainVBox);
                
                actualChannelNumber = this.ImObj.Channel(jj);
                if ~isnan(actualChannelNumber)
                    chanstr = sprintf('Channel %s',this.ChannelLabels{actualChannelNumber});
                else
                    chanstr = 'Extra Channel';
                end
                this.ChannelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj},'style','checkbox',...
                       'string',chanstr,'Value',true,'callback',@(src,evt)this.showImage());

                defcol = this.ColourMaps{jj}{1};
                if isnumeric(defcol) && numel(defcol)==3 && ~any(defcol~=1)
                    % white colour, change to grey if there are other
                    % colours
                    allcol = cell2mat(arrayfun(@(x)x{1}{1},this.ColourMaps,'uni',false));
                    if any(std(allcol,0,2)>0 & any(allcol<1,2))
                        this.ColourMaps{jj}{1} = [0.4,0.4,0.4];
                    end
                end
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
                    set(this.DispToolArray{jj},'widths',[120,24*ones(1,numel(this.ColourMaps{jj})),-1]);
                catch ME
                    rethrow(ME)
                end

            end
            set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ColourMaps))],'Spacing', 5);

        end

        function toggleHide(this,src,evt)
            if isempty(get(this.DispToolArray{1},'parent'))
                this.showToolbar();
            else
                this.hideToolbar();
            end
        end
        
        function hideToolbar(this)
            if ~isempty(get(this.DispToolArray{1},'parent'))
                % needs to be removed
                for ii = 1:numel(this.DispToolArray)
                    set(this.DispToolArray{ii},'parent',[])
                end
                set(this.HideButton,'string',char(9650))
                set(this.MainVBox,'heights',[-1,12]);
            end
        end
        
        function showToolbar(this)
            if isempty(get(this.DispToolArray{1},'parent'))
                % needs to be reattached
                for ii = 1:numel(this.DispToolArray)
                    set(this.DispToolArray{ii},'parent',this.MainVBox)
                end
                set(this.HideButton,'string',char(9660))
                set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.DispToolArray))]);
            end
        end

        function colourCallback(this,src,evt,ch,ind)
            % this callback will be different from the single channel case,
            % because the images have to be merged.

            % Depending on the speed, it might be worth keeping a copy of
            % the contrast-adjusted data in the class..


            % flag the chosen coloumap for recalculation
            % this happens when the contrast or colour of the channel is changed.
            
            this.UseMaps{ch} = [];
            
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
                    
% %                 set(this.ImgHandle,'cdata',cdata);
                    api = iptgetapi(this.hSP);
                    api.replaceImage(cdata,'PreserveView',true);
                    
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



% %         function gh = getSnapshotHandle(this)
% % %             gh = this.AxHandle;
% %             gh = this.hSP;
% %         end
        
        function varargout = snapshotCopy(this,figh)
            % try a different approach, whereby the object is copied and
            % returned within the display class
            api = iptgetapi(this.hSP);
            imlim = api.getVisibleImageRect();
            
            aspr = imlim(3)/imlim(4);
            set(figh,'paperunits','inches','paperposition',[0.1,1,16,16/aspr])
            
            gh = copyobj(this.AxHandle,figh);
            set(gh,'units','normalized','position',[0,0,1,1]);
            set(gh,'xlim',[imlim(1),imlim(1)+imlim(3)],'ylim',[imlim(2),imlim(2)+imlim(4)])
            
            % get the point factor based on what the magnification is
            mag = api.getMagnification();
% %             
% %             pointfactor = 16*72 / mag;
            pointfactor = 1/mag;

            widhandles = findobj(gh,'-property','linewidth');
            for ii = 1:numel(widhandles)
                set(widhandles(ii),'linewidth',pointfactor*get(widhandles(ii),'linewidth'));
            end
            
            if nargout>0
                varargout{1} = gh;
            end
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
        
        function scalebarcallback(this,src,evt,option)
            % Want to have a set of scales, and then default to the one
            % that is closest to the size that we want on the screen
            
            if any(this.ImObj.PixelSize==0)
                msgbox('No scale info in the image')
                return
            end
            
            delete(this.ScaleHandle)
            delete(this.ScaleText)
            if strcmpi(option,'hide')
                this.ScaleHandle = [];
                this.ScaleText = [];
                return
            end
            
            if strcmpi(option,'poscycle')
                switch this.ScaleBarInfo.Location
                    case 'bl'
                        this.ScaleBarInfo.Location = 'tl';
                    case 'tl'
                        this.ScaleBarInfo.Location = 'tr';
                    case 'tr'
                        this.ScaleBarInfo.Location = 'br';
                    case 'br'
                        this.ScaleBarInfo.Location = 'bl';
                        
                end
            end
            
            api = iptgetapi(this.hSP);
            currpixsiz = this.ImObj.PixelSize(1)/api.getMagnification();
            [pixlen,physlen] = this.ScaleBarInfo.getLengths(currpixsiz);

            axlen = pixlen/api.getMagnification();

            visrect = api.getVisibleImageRect();

            if this.ScaleBarInfo.Location(2)=='l'
                leftpos = visrect(1) + 0.05*visrect(3);
            else
                leftpos = visrect(1) + 0.95*visrect(3) - axlen;
            end

            if this.ScaleBarInfo.Location(1)=='t'
                vpos = visrect(2) + 0.05*visrect(4);
                textoffset = 0.05*visrect(4);
            else
                vpos = visrect(2) + 0.95*visrect(4);
                textoffset = -0.05*visrect(4);
            end

            this.ScaleHandle = line('parent',this.AxHandle,...
                'xdata',leftpos+[0,axlen],'ydata',vpos+[0,0],...
                'linestyle','-','color',this.ScaleBarInfo.Colour,...
                'linewidth',this.ScaleBarInfo.Thickness);
            
            
            this.ScaleText = text('parent',this.AxHandle,...
                'position',[leftpos + 0.3*axlen,vpos+textoffset],...
                'FontSize',16,'String',sprintf('%d \\mum',physlen),...
                'Color',this.ScaleBarInfo.Colour);
            
        end
    end
end
