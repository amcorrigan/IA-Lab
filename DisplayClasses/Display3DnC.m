classdef Display3DnC < cDisplayInterface
    % Current beta for 3D multichannel displays
    %
    % TO DO:
    % - the ImData is slow to get from the image object, so either speed up
    %   getting raw data, or store in the class
    % - panning is very jittery, need to work out how this can be fixed
    % - setting and displaying the current slices is still not done. One
    %   reason for this is that it isn't clear how the slices should get
    %   updated when panning and zooming is done? Simplest case is not at
    %   all..

    properties
        ParentHandle % the handle of the containing graphics object

        FigParent % Useful to store a direct reference to the parent figure, for handling callbacks
%         AxHandle
        AxXY
        AxXZ
        AxYZ
        CornerPanel

        ImgHandleXY = [];
        ImgHandleXZ = [];
        ImgHandleYZ = [];

        SliderZ
        SliderY
        SliderX
        SliderTextZ
        SliderTextY
        SliderTextX

        MainVBox
        HideButton
        DispToolArray = {};
        ToolHBox
        
        CrosshairButton
        PlotHandles
        
        % placeholder for being able to pass information (axes limits,
        % colourmap, etc) from an existing display
        % it's not been used yet, but I think it should be part of the
        % interface (passed in the constructor) for future functionality
        setupInfo = [];
        
        ImData
        ImObj
        ImSizes
        ViewSize
        UseZInds % to stack together 3D images with different numbers of slices

        UseMaps

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

        ChannelShowCheckBoxes

        hSP=[];
        hOvPanel = [];

        PrevMousePosition

        FlexGrid
        GridLstn

        CurrXYZ
        ScrollMode = 0;
        
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
        function this = Display3DnC(parenth,contrastObj,info)
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
            while isa(aHandle, 'matlab.ui.Figure') == 0 && ~(ishandle(aHandle) && strcmp(get(aHandle,'type'),'figure'))
                aHandle = get(aHandle,'Parent');
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

            %  Context menu (right click)
            %-- If the current parent uiControl is NOT a figure, go ask its parent

            this.CxtMenu = uicontextmenu('parent',this.FigParent);
            uimenu(this.CxtMenu,'label','Zoom in', 'CallBack', {@this.contextcallback, 'Zoom in'});
            uimenu(this.CxtMenu,'label','Zoom out', 'CallBack', {@this.contextcallback, 'Zoom out'});
            uimenu(this.CxtMenu,'label','Fit the window', 'CallBack', {@this.contextcallback, 'Fit the window'});
            uimenu(this.CxtMenu,'label','Close Tab', 'CallBack', {@this.contextcallback, 'Close Tab'},...
                         'separator', 'on');
            uimenu(this.CxtMenu,'label','Close All', 'CallBack', {@this.contextcallback, 'Close All'});
            
            uimenu(this.CxtMenu,'label','Maximum projection','CallBack',@this.maxprojcallback,...
                'separator','on');
            
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
                this.populateCMaps();
            end
            if ~isempty(this.ImObj)

                if isempty(this.AxXY)
                    setupDisplay(this);
                end

                [cdataxy,cdataxz,cdatayz] = this.calculateImage;

                if isempty(this.ImgHandleXY)
                    if ~isempty(cdataxy)
                        this.ImgHandleXY = imagesc('parent',this.AxXY,'cdata',cdataxy);
                    end
                    if ~isempty(cdataxz)
                        this.ImgHandleXZ = imagesc('parent',this.AxXZ,'cdata',cdataxz);
                    end
                    if ~isempty(cdatayz)
                        this.ImgHandleYZ = imagesc('parent',this.AxYZ,'cdata',cdatayz);
                    end
                    
                    set([this.AxXY,this.AxXZ],'ydir','normal')
                    
                    set(this.FigParent,'WindowKeyPressFcn',@this.keypressfun)
                    set(this.ImgHandleXY,'ButtonDownFcn',{@this.mousepressfun,3})
                    set(this.ImgHandleXZ,'ButtonDownFcn',{@this.mousepressfun,2})
                    set(this.ImgHandleYZ,'ButtonDownFcn',{@this.mousepressfun,1})
                    
                    this.ImgHandleXY.UIContextMenu = this.CxtMenu;
                    this.ImgHandleXZ.UIContextMenu = this.CxtMenu;
                    this.ImgHandleYZ.UIContextMenu = this.CxtMenu;
                    
                    this.AxXY.UIContextMenu = this.CxtMenu;
                    this.AxXZ.UIContextMenu = this.CxtMenu;
                    this.AxYZ.UIContextMenu = this.CxtMenu;
                    
                    % draw the crosshairs
                    this.updateCrosshairs();
                    
                else
                    
                    set(this.ImgHandleXY,'cdata',cdataxy);
                    set(this.ImgHandleXZ,'cdata',cdataxz);
                    set(this.ImgHandleYZ,'cdata',cdatayz);
                end

                %-- This may take a long time to run.
%                 drawnow();


                % only do this if it hasn't been done already?
                if strcmpi(get(this.AxXY,'XLimMode'),'auto')
                    set(this.AxXY,'xlim',[0,this.ImObj.SizeY],'ylim',[0,this.ImObj.SizeX])
                    set(this.AxXZ,'xlim',[0,max(this.ImObj.NumZSlice)],'ylim',[0,this.ImObj.SizeX])
                    set(this.AxYZ,'xlim',[0,this.ImObj.SizeY],'ylim',[0,max(this.ImObj.NumZSlice)])
                    
                    linkaxes([this.AxXY,this.AxXZ],'y')
                    linkaxes([this.AxXY,this.AxYZ],'x')
                    axis(this.AxXY,'equal') % will this mess things up?
                end
                
            else
                this.ImgHandleXY = NaN;
                this.ImgHandleXZ = NaN;
                this.ImgHandleYZ = NaN;
            end

            if nargout>0
                varargout{1} = {this.ImgHandleXY,this.ImgHandleXZ,this.ImgHandleYZ};
            end

        end
        
        function populateCMaps(this)
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

        function setupDisplay(this)
            this.MainVBox = uix.VBox('parent',this.ParentHandle);

            hPanel = uipanel('Parent', this.MainVBox, 'units','normalized');
            set(hPanel,'Position',[0 0 1 1]);

% %             this.FlexGrid = uix.GridFlex( 'Parent', hPanel, 'Spacing', 3 );
            this.FlexGrid = AmcGridFlex( 'Parent', hPanel, 'Spacing', 3 );


            this.CornerPanel = uipanel('parent',this.FlexGrid);

            this.AxXZ = axes('parent',this.FlexGrid,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
%             axis(this.AxXZ,'equal');
            axis(this.AxXZ,'ij');

            this.AxYZ = axes('parent',this.FlexGrid,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
%             axis(this.AxYZ,'equal');
            axis(this.AxYZ,'ij');

            this.AxXY = axes('parent',this.FlexGrid,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
%             axis(this.AxXY,'equal');
            axis(this.AxXY,'ij');

            set( this.FlexGrid, 'Widths', [-1, -5], 'Heights', [-1, -5] ,...
                'SizeChangedFcn',@this.syncAxes);
            
            
            % can we set up a listener to detect when the grid is dragged?
% %             this.GridLstn = addlistener(this.FlexGrid,'Heights','PostSet',@this.syncAxes);
% %             this.GridLstn(2) = addlistener(this.FlexGrid,'Widths','PostSet',@this.syncAxes);
            
            this.FlexGrid.setDragFcn(@this.syncAxes);
            
            % why is the button inside a vbox?
            temp = uix.HBox('parent',this.MainVBox);
            this.HideButton = uicontrol('Style','pushbutton','parent',temp,'callback',...
                @this.toggleHide,'String',char(9660));


            this.ToolHBox = uix.HBox('parent',this.MainVBox);
            vbox1 = uix.VBox('parent',this.ToolHBox,'Spacing', 5);
            gbox2 = uix.Grid('parent',this.ToolHBox);
            
            this.CrosshairButton = uicontrol('style','togglebutton','parent',this.ToolHBox,...
                'callback',@this.toggleCrosshairs,'value',1,'String','Crosshairs');

            set(this.ToolHBox,'widths',[-1,-1,60]);
            
            if isempty(this.ChannelLabels)
                % if we haven't supplied labels for the channels, create
                % default ones here
                numChan = numel(this.ColourMaps);
                this.ChannelLabels = arrayfun(@num2str,(1:numChan)','uni',false);
            end

            for jj = 1:numel(this.ColourMaps)



                this.DispToolArray{jj} = uix.HBox('parent',vbox1);


                actualChannelNumber = this.ImObj.Channel(jj);
                chanstr = sprintf('Channel %s',this.ChannelLabels{actualChannelNumber});
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

            
            this.SliderX = uicontrol('style','slider','parent',gbox2,...
                'backgroundcolor',[0.9,0.7,0.7]);
            this.SliderY = uicontrol('style','slider','parent',gbox2,...
                'backgroundcolor',[0.7,0.7,0.9]);
            this.SliderZ = uicontrol('style','slider','parent',gbox2,...
                'backgroundcolor',[0.7,0.9,0.7]);
            
            this.SliderTextX = uicontrol('style','text','string','X','parent',gbox2);
            this.SliderTextY = uicontrol('style','text','string','Y','parent',gbox2);
            this.SliderTextZ = uicontrol('style','text','string','Z','parent',gbox2);
            
            
            set(gbox2,'widths',[-6,-1],'heights',[-1,-1,-1],'spacing',3);

            set(this.MainVBox,'heights',[-1,12,max(40,24*numel(this.ColourMaps))]);

        end
        
        function [cdataxy,cdataxz,cdatayz] = calculateImage(this,dimstr)
            % data is returned as cell array of double, which should be
            % fine for contrast adjustment
            %-- maybe save the pdata as artributes.
            %-- To do: how to invert colour
            
            cdataxy = [];
            cdataxz = [];
            cdatayz = [];
            
            if nargin<2 || isempty(dimstr)
                dimstr = 'xyz'; % update all by default
                % alternatively, a difference between CurrXYZ and the
                % slider values could be used as an automatic flag to
                % update the panel - is this robust enough?
            end
            
            % rewritten so that it's the colourmap that has the contrast
            % adjustment applied, rather than the image..
            % This is almost fast enough without storing the individual
            % channels, but it could be done so that the individual
            % testmaps are stored and then marked as dirty if they need to
            % be recalculated, eg by colourcallback

            this.ImData = this.ImObj.getDataC3D(); % we should ensure that this method returns a uint16 array
            this.ImSizes = cell2mat(cellfun(@(x)[size(x,1),size(x,2),size(x,3)],this.ImData,'uni',false));
            
            % examine the z-sizes to make sure that they're all the same
            % size - if they're not calculate the nearest slice to use in
            % each case
            maxZ = max(this.ImSizes(:,3));
            this.UseZInds = max(1,ceil(bsxfun(@times,this.ImSizes(:,3),linspace(0,1,maxZ))));
            
            
            this.ViewSize = [min(this.ImSizes(:,1)),min(this.ImSizes(:,2)),max(this.ImSizes(:,3))];
            % this is currently different to the 2D version, which trims
            % around the edge of images which are larger than the rest
            
            if isempty(this.CurrXYZ)
                
                this.CurrXYZ = ceil(this.ViewSize/2);

                set(this.SliderZ,'min',1,'max',this.ViewSize(3),'Value',this.CurrXYZ(3),...
                    'callback',@this.sliderZCallback,'sliderstep',[1,5]/this.ViewSize(3))
                set(this.SliderY,'min',1,'max',this.ViewSize(2),'Value',this.CurrXYZ(2),...
                    'callback',@this.sliderYCallback,'sliderstep',[1/this.ViewSize(2),0.05])
                set(this.SliderX,'min',1,'max',this.ViewSize(1),'Value',this.CurrXYZ(1),...
                    'callback',@this.sliderXCallback,'sliderstep',[1/this.ViewSize(1),0.05])

            end

            % want to separate the cdata into three separate method calls, so that
            % when the slice is changed, they can be updated individually
            if strfind(dimstr,'z')
                cdataxy = this.calculateXYData(); % pass imdata and imsizes rather than getting them each time
            end
            if strfind(dimstr,'y')
                cdataxz = this.calculateXZData();
            end
            if strfind(dimstr,'x')
                cdatayz = this.calculateYZData();
            end

        end

        function cdataxy = calculateXYData(this)
            % need three different cdatas, for the three views
            cdataxy = zeros(this.ViewSize(1)*this.ViewSize(2),3,'uint8');

            % value to start at
            lowerval = 1 + floor(bsxfun(@minus,this.ImSizes,min(this.ImSizes,[],1))/2);

            % value to end at
            upperval = this.ImSizes - ceil(bsxfun(@minus,this.ImSizes,min(this.ImSizes,[],1))/2);
            
            % treat the z-direction slightly differently - the images
            % should already have been resized to have the same dimensions
            
            for ii = 1:numel(this.ColourMaps) % number of channels
                if get(this.ChannelShowCheckBoxes(ii),'value')
                    if isempty(this.UseMaps{ii})
                        tempMap = this.ColourMaps{ii}{this.CurrMap(ii)};
                        if size(tempMap,1)==1
                            % get it working first, then look for speed
                            % improvements
                            % YINHAI IMPROVED
                            tempMap = uint8(255*colorGradient([0,0,0],tempMap,256));
%                             tempMap = uint8(255*createcmap([0,0,0;tempMap],256));
                        end


                        % apply contrast adjustment to the colourmap
                        testind = uint8(this.ConObj.getLUT(this.ImObj.Channel(ii))*255);
                        this.UseMaps{ii} = tempMap(testind+1,:);
                    end
                    % XY
                    try
% %                     temp = this.ImData{ii}(lowerval(ii,1):upperval(ii,1),lowerval(ii,2):upperval(ii,2),this.CurrXYZ(3));
                    temp = this.ImData{ii}(lowerval(ii,1):upperval(ii,1),lowerval(ii,2):upperval(ii,2),this.UseZInds(ii,this.CurrXYZ(3)));
                    
                    cdataxy = max(cdataxy,this.UseMaps{ii}(temp(:)+1,:));
                    catch ME
                        rethrow(ME)
                    end
                end
            end

            cdataxy = reshape(cdataxy,[this.ViewSize(1),this.ViewSize(2),3]);

        end


        function cdataxz = calculateXZData(this)
            % need three different cdatas, for the three views
% %             cdataxz = zeros(size(this.ImData{1},1)*size(this.ImData{1},3),3,'uint8');
            cdataxz = zeros(this.ViewSize(1)*this.ViewSize(3),3,'uint8');
            % start off with a column vector, one row per pixel and reshape
            % at the end

            % value to start at
            lowerval = 1 + floor(bsxfun(@minus,this.ImSizes,min(this.ImSizes,[],1))/2);

            % value to end at
            upperval = this.ImSizes - ceil(bsxfun(@minus,this.ImSizes,min(this.ImSizes,[],1))/2);

            for ii = 1:numel(this.ColourMaps) % number of channels
                if get(this.ChannelShowCheckBoxes(ii),'value')
                    if isempty(this.UseMaps{ii})
                        tempMap = this.ColourMaps{ii}{this.CurrMap(ii)};
                        if size(tempMap,1)==1
                            % get it working first, then look for speed
                            % improvements
                            % YINHAI IMPROVED
                            tempMap = uint8(255*colorGradient([0,0,0],tempMap,256));
%                             tempMap = uint8(255*createcmap([0,0,0;tempMap],256));
                        end


                        % apply contrast adjustment to the colourmap
                        testind = uint8(this.ConObj.getLUT(this.ImObj.Channel(ii))*255);
                        this.UseMaps{ii} = tempMap(testind+1,:);
                    end

                    % XZ
                    temp = this.ImData{ii}(lowerval(ii,1):upperval(ii,1),this.CurrXYZ(2),this.UseZInds(ii,:));
                    cdataxz = max(cdataxz,this.UseMaps{ii}(temp(:)+1,:));

                end
            end

            cdataxz = reshape(cdataxz,[this.ViewSize(1),this.ViewSize(3),3]);

        end


        function cdatayz = calculateYZData(this)
            % need three different cdatas, for the three views
            cdatayz = zeros(this.ViewSize(3)*this.ViewSize(2),3,'uint8');
            % start off with a column vector, one row per pixel and reshape
            % at the end

            % value to start at
            lowerval = 1 + floor(bsxfun(@minus,this.ImSizes,min(this.ImSizes,[],1))/2);

            % value to end at
            upperval = this.ImSizes - ceil(bsxfun(@minus,this.ImSizes,min(this.ImSizes,[],1))/2);

            for ii = 1:numel(this.ColourMaps) % number of channels
                if get(this.ChannelShowCheckBoxes(ii),'value')
                    if isempty(this.UseMaps{ii})
                        tempMap = this.ColourMaps{ii}{this.CurrMap(ii)};
                        if size(tempMap,1)==1
                            % get it working first, then look for speed
                            % improvements
                            % YINHAI IMPROVED
%                             tempMap = uint8(255*createcmap([0,0,0;tempMap],256));
                            tempMap = uint8(255*colorGradient([0,0,0],tempMap,256));
                        end


                        % apply contrast adjustment to the colourmap
                        testind = uint8(this.ConObj.getLUT(this.ImObj.Channel(ii))*255);
                        this.UseMaps{ii} = tempMap(testind+1,:);
                    end

                    % YZ
                    temp = permute(this.ImData{ii}(this.CurrXYZ(1),lowerval(ii,2):upperval(ii,2),this.UseZInds(ii,:)),[3,2,1]);
                    cdatayz = max(cdatayz,this.UseMaps{ii}(temp(:)+1,:));


                end
            end

            cdatayz = reshape(cdatayz,[this.ViewSize(3),this.ViewSize(2),3]);

        end
        
        
        function scrollfun(this,src,evt)
            % detect if a modifier is being held down
% %             temp = get(src,'CurrentKey');
% %             
% %             if ~strcmpi(temp,'control')
            
            if this.ScrollMode==0
%                 axis(this.AxXY,'equal') % will this mess things up?
                % use mouse scrolling to adjust the zoom in small increments
%                 zoomfact = 1.2^(-evt.VerticalScrollCount); % 20% zoom for each scroll
                
                % will changing the XY view be enough?
                currxlim = get(this.AxXY,'xlim');
                currylim = get(this.AxXY,'ylim');
                
%                 tmat = [0.9,0.1;0.1,0.9];
                tmat = [1,0;0,1] + 0.1*evt.VerticalScrollCount*[1,-1;-1,1];
                
                newxlim = currxlim*tmat;
                newylim = currylim*tmat;
                
                try % this line sometimes seems to cause an error
                set(this.AxXY,'xlim',newxlim, 'ylim',newylim)
                catch me
                    rethrow(me)
                end
                
                if ~isempty(this.ScaleHandle)
                    this.scalebarcallback([],[],'refresh')
                end

            else
                % it's the z-slice that we want to increment
                
                newxyz = [this.CurrXYZ(1:2),max(1,min(this.ViewSize(3),this.CurrXYZ(3) - evt.VerticalScrollCount))];
                
                this.sliceUpdate(newxyz);
                
                % update the slider
                set(this.SliderZ,'value',this.CurrXYZ(3));
            end
            
            

        end
        
        function keypressfun(this,src,evt)
            % check if the key is ctrl, and if so, change the scroll mode
            if ~isempty(evt.Character) || isempty(evt.Modifier)
                return
            end
            if numel(evt.Modifier)==1 && strcmpi(evt.Modifier{1},'control')
                this.ScrollMode = 1;
                set(this.FigParent,'WindowKeyReleaseFcn',@this.keyreleasefun)
            end
            
            
        end
        
        function keyreleasefun(this,src,evt)
            this.ScrollMode = 0;
            set(this.FigParent,'WindowKeyReleaseFcn','')
        end
        
        function mousepressfun(this,src,evt,dim)
            % mouse button pressed
            % left button means set current point
            
            % middle button means activate pan mode
            switch get(this.FigParent,'SelectionType')
                case 'normal'
                    % this is the pan, consistent with the 2D viewer
                    
                    set(this.FigParent,'Pointer','fleur',...
                        'WindowButtonMotionFcn',@this.cursormovefun,...
                        'WindowButtonUpFcn',@this.buttonupfun)

                    % record the current cursor location in order to calculate
                    % movement
                    this.PrevMousePosition = get(this.AxXY,'CurrentPoint');
                case 'extend'
                    % this should be focus position?
                    
                    switch dim
                        case 1
                            pos = get(this.AxYZ,'CurrentPoint');
                            newxyz = [this.CurrXYZ(1),pos(1,1),pos(1,2)];
                        case 2
                            pos = get(this.AxXZ,'CurrentPoint');
                            newxyz = [pos(1,2),this.CurrXYZ(2),pos(1,1)];
                        otherwise
                            pos = get(this.AxXY,'CurrentPoint');
                            newxyz = [pos(1,2),pos(1,1),this.CurrXYZ(3)];
                    end
                    this.sliceUpdate(newxyz);
                    
                    set(this.PlotHandles(ishandle(this.PlotHandles)),'visible','on')
                    set(this.FigParent,'WindowButtonUpFcn',@this.middleupfun)
            end
        end

        function cursormovefun(this,src,evt)
            
            set(this.FigParent,'WindowButtonMotionFcn','')
            currpos = get(this.AxXY,'CurrentPoint');

            % calculate the distance moved
            delta = (this.PrevMousePosition(1,1:2) - currpos(1,1:2));

%             this.PrevMousePosition = currpos;
            
            currxlim = get(this.AxXY,'xlim');
            currylim = get(this.AxXY,'ylim');
            
            % need to adjust these, but not beyond the limits of the image
            tempxlim = currxlim + delta(1);
            tempylim = currylim + delta(2);
            
            set(this.AxXY,'xlim',tempxlim,'ylim',tempylim)
            this.PrevMousePosition = get(this.AxXY,'CurrentPoint');

            set(this.FigParent,'WindowButtonMotionFcn',@this.cursormovefun)
            
            if ~isempty(this.ScaleHandle)
                this.scalebarcallback([],[],'refresh')
            end

        end

        function buttonupfun(this,src,evt)
            set(this.FigParent','WindowButtonMotionFcn','',...
                'WindowButtonUpFcn','','Pointer','arrow');
        end
        
        function middleupfun(this,src,evt)
            % remove the crosshairs if required
            set(this.FigParent,'WindowButtonUpFcn',@this.middleupfun)
            
            if ~get(this.CrosshairButton,'value')
                set(this.PlotHandles(ishandle(this.PlotHandles)),'visible','off')
            end
            
            
        end
        
        function funhand = getScrollFun(this)
            % hopefully this works as expected.
            funhand = @this.scrollfun;
        end
        
        function sliderXCallback(this,src,evt)
            newplane = round(get(src,'Value'));
            set(src,'Value',newplane)
%             set(this.SliderZText,'string',sprintf('Z=%d',this.CurrSlice))
            
            newXYZ = [newplane,this.CurrXYZ(2:3)];
            this.sliceUpdate(newXYZ);
            
            
        end
        
        function sliderYCallback(this,src,evt)
            newplane = round(get(src,'Value'));
            set(src,'Value',newplane)
%             set(this.SliderZText,'string',sprintf('Z=%d',this.CurrSlice))
            
            newXYZ = [this.CurrXYZ(1),newplane,this.CurrXYZ(3)];
            this.sliceUpdate(newXYZ);
            
            
        end

        function sliderZCallback(this,src,evt)
            newplane = round(get(src,'Value'));
            set(src,'Value',newplane)
%             set(this.SliderZText,'string',sprintf('Z=%d',this.CurrSlice))
            
            newXYZ = [this.CurrXYZ(1:2),newplane];
            this.sliceUpdate(newXYZ);
            
            
        end

        function sliceUpdate(this,newXYZ)
            
% %             imsiz = [size(this.ImData{1},1),size(this.ImData{1},2),size(this.ImData{1},3)];
            newXYZ = max(1,min(this.ViewSize,round(newXYZ)));
            
            changeDim = this.CurrXYZ ~= newXYZ;
            this.CurrXYZ = newXYZ;
            
            if changeDim(1)
                % YZ needs updating
                set(this.ImgHandleYZ,'cdata',calculateYZData(this));
                
                % also update the slider
                set(this.SliderX,'Value',this.CurrXYZ(1))
                set(this.SliderTextX,'String',sprintf('X=%d',this.CurrXYZ(1)))
            end
            
            if changeDim(2)
                % XZ needs updating
                set(this.ImgHandleXZ,'cdata',calculateXZData(this));
                
                % also update the slider
                set(this.SliderY,'Value',this.CurrXYZ(2))
                set(this.SliderTextY,'String',sprintf('Y=%d',this.CurrXYZ(2)))
            end
            
            if changeDim(3)
                % XY needs updating
                set(this.ImgHandleXY,'cdata',calculateXYData(this));
                
                % also update the slider
                set(this.SliderZ,'Value',this.CurrXYZ(3))
                set(this.SliderTextZ,'String',sprintf('Z=%d',this.CurrXYZ(3)))
            end
            
            this.updateCrosshairs();
            
            
        end
        
        function updateCrosshairs(this)
            if isempty(this.PlotHandles)
                % first time plotted
                this.PlotHandles = line('parent',this.AxXY,'xdata',[1,1]*this.CurrXYZ(2),...
                    'ydata',[0,this.ViewSize(1)],'linestyle','-','color','b');
                this.PlotHandles(2) = line('parent',this.AxXY,'xdata',[0,this.ViewSize(2)],...
                    'ydata',[1,1]*this.CurrXYZ(1),'linestyle','-','color','r');
                
                this.PlotHandles(3) = line('parent',this.AxXZ,'xdata',[1,1]*this.CurrXYZ(3),...
                    'ydata',[0,this.ViewSize(1)],'linestyle','-','color','g');
                this.PlotHandles(4) = line('parent',this.AxXZ,'xdata',[0,this.ViewSize(3)],...
                    'ydata',[1,1]*this.CurrXYZ(1),'linestyle','-','color','r');
                
                this.PlotHandles(5) = line('parent',this.AxYZ,'xdata',[1,1]*this.CurrXYZ(2),...
                    'ydata',[0,this.ViewSize(3)],'linestyle','-','color','b');
                this.PlotHandles(6) = line('parent',this.AxYZ,'xdata',[0,this.ViewSize(2)],...
                    'ydata',[1,1]*this.CurrXYZ(3),'linestyle','-','color','g');
                
                set(this.PlotHandles(1:2),'buttondownfcn',{@this.mousepressfun,3})
                set(this.PlotHandles(3:4),'buttondownfcn',{@this.mousepressfun,2})
                set(this.PlotHandles(5:6),'buttondownfcn',{@this.mousepressfun,1})
                
                
            else
                % lines already exist
                set(this.PlotHandles([1,5]),'xdata',[1,1]*this.CurrXYZ(2))
                set(this.PlotHandles([2,4]),'ydata',[1,1]*this.CurrXYZ(1))
                set(this.PlotHandles(3),'xdata',[1,1]*this.CurrXYZ(3))
                set(this.PlotHandles(6),'ydata',[1,1]*this.CurrXYZ(3))
                
            end
        end


        function syncAxes(this,src,evt)
            if ~isempty(this.AxXY)
                axis(this.AxXY,'equal')
            end
        end
        
        function toggleHide(this,src,evt)
            if isempty(get(this.ToolHBox,'parent'))
                this.showToolbar();
            else
                this.hideToolbar();
            end
        end
        
        function hideToolbar(this)
            if ~isempty(get(this.ToolHBox,'parent'))
                % needs to be removed
                set(this.ToolHBox,'parent',[])

                set(this.HideButton,'string',char(9650))
                set(this.MainVBox,'heights',[-1,12]);
            end
        end
        
        function showToolbar(this)
            if isempty(get(this.ToolHBox,'parent'))
                % needs to be reattached
                set(this.ToolHBox,'parent',this.MainVBox)

                set(this.HideButton,'string',char(9660))
                set(this.MainVBox,'heights',[-1,12,24*numel(this.ColourMaps)]);
            end
        end

        function toggleCrosshairs(this,src,evt)
            if get(src,'value')
                set(this.PlotHandles(ishandle(this.PlotHandles)),'visible','on')
            else
                set(this.PlotHandles(ishandle(this.PlotHandles)),'visible','off')
            end
        end
        
        function colourCallback(this,src,evt,ch,ind)
            % this callback will be different from the single channel case,
            % because the images have to be merged.

            % Depending on the speed, it might be worth keeping a copy of
            % the contrast-adjusted data in the class..

            % mark the colourmap as needed to be recalculated
            this.UseMaps{ch} = [];

            % we can call this method from outside to flag a colourmap as
            % needing to be recalculated, just leave the src empty

            if ~isempty(src)
                if ind==numel(this.ColourMaps{ch})
                    % custom colour
                    this.ColourMaps{ch}{ind} = uisetcolor('Choose a new colour');
                    set(src,'backgroundColor',this.ColourMaps{ch}{ind});
                    set(src,'foregroundColor',1-this.ColourMaps{ch}{ind});
                end
                this.CurrMap(ch) = ind;

                if ishandle(this.ImgHandleXY)
                    [cdataxy,cdataxz,cdatayz] = this.calculateImage;
                    try
                    set(this.ImgHandleXY,'cdata',cdataxy);
                    set(this.ImgHandleXZ,'cdata',cdataxz);
                    set(this.ImgHandleYZ,'cdata',cdatayz);

% %                         api = iptgetapi(this.hSP);
% %                         api.replaceImage(cdata,'PreserveView',true);
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
            if isempty(this.ImgHandleXY)
                cdata = NaN*ones(siz);
            else
                % how slow is this?
                cdata = imresize(get(this.ImgHandleXY,'cdata'),[siz,siz]);
            end
        end

% %         function gh = getSnapshotHandle(this)
% %             gh = get(this.FlexGrid,'parent'); % the panel that contains the grid
% %         end
        function varargout = snapshotCopy(this,figh)
            % try a different approach, whereby the object is copied and
            % returned within the display class
            
            % This isn't yet completed
% %             IAHelp()
% %             return
            

%             gh = copyobj(get(this.FlexGrid,'parent'),figh);
            % uix.FlexGrid is very poorly designed for this, will need to
            % get the individual axes
            gh = uix.Grid('parent',figh,'spacing',3);
            uix.Panel('parent',gh,'visible','off');
            
            tempfig = figure('visible','off');
            % figure for staging the axes
            axxz = copyobj(this.AxXZ,tempfig);
            set(axxz,'parent',gh);
%             
%             tempfig2 = figure('visible','on');
            axyz = copyobj(this.AxYZ,tempfig);
            set(axyz,'parent',gh);
            
%             tempfig3 = figure('visible','on');
            axxy = copyobj(this.AxXY,tempfig);
            set(axxy,'parent',gh);
            
            set(gh,'widths',get(this.FlexGrid,'widths'),...
                'heights',get(this.FlexGrid,'heights'));
            
            set(gh,'units','normalized','position',[0,0,1,1]);
%             set(gh,'xlim',[imlim(1),imlim(1)+imlim(3)],'ylim',[imlim(2),imlim(2)+imlim(4)])
            

            % might have to sync the axes limits again..
            axis(axxy,'fill')
            temp = get(axxy,'xlim');
            temp2 = get(this.AxXY,'xlim');
            newxlim = [temp2(1),temp2(1)-temp(1) + temp(2)];
            
            temp = get(axxy,'ylim');
            temp2 = get(this.AxXY,'ylim');
            newylim = [temp2(1),temp2(1)-temp(1) + temp(2)];
            
            set(axxy,'xlim',newxlim,'ylim',newylim)
            set(axxz,'ylim',newylim)
            set(axyz,'xlim',newxlim)
            
            
            % get the point factor based on what the magnification is
            mag = 0.8; % guess this for now, can try to find the true value based on
            % screen location if required
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
                    currxlim = get(this.AxXY,'xlim');
                    currylim = get(this.AxXY,'ylim');

                    tmat = [0.75,0.25;0.25,0.75];
                    
                    newxlim = currxlim*tmat;
                    newylim = currylim*tmat;

                    set(this.AxXY,'xlim',newxlim, 'ylim',newylim)
                case 'Zoom out'
                    currxlim = get(this.AxXY,'xlim');
                    currylim = get(this.AxXY,'ylim');

                    tmat = [1.25,-0.25;-0.25,1.25];
                    
                    newxlim = currxlim*tmat;
                    newylim = currylim*tmat;

                    set(this.AxXY,'xlim',newxlim, 'ylim',newylim)
                case 'Fit the window'
                    set(this.AxXY,'xlim',[1,this.ViewSize(2)], 'ylim',[1,this.ViewSize(1)])
                case 'Close Tab'
                    data = GenEvtData(1);
                    notify(this,'closeRequest',data)
                case 'Close All'
                    data = GenEvtData('all');
                    notify(this,'closeRequest',data)
            end
        end
        
        function maxprojcallback(this,src,evt)
            % generate a maximum projection of the image and ask for it to
            % be displayed in a new window
            %
            % depending on the parent, it will be another tab or an
            % independent window (DisplayManager vs azDisplayFig)
            
            imdata = cellfun(@(x)max(x,[],3),this.ImObj.getDataC3D(),'uni',false);
            im2DObj = cImage2DnC([],[],this.ImObj.NativeColour,this.ImObj.Channel,this.ImObj.PixelSize(1:2),'Max',imdata);
            
            data = GenEvtData(im2DObj);
            notify(this,'imageEvent',data);
            
        end
        
        function scalebarcallback(this,src,evt,option)
            % Want to have a set of scales, and then default to the one
            % that is closest to the size that we want on the screen
            
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
            
            % unless we know the absolute size of the axes, there's no way
            % of knowing what the length of the bar on the screen (in
            % pixels) is going to be
            
            % let's hope we can trust the axes position property
            set(this.AxXY,'units','pixels') % should be this already..
            axpos = get(this.AxXY,'position');
            xlim = get(this.AxXY,'xlim');
            ylim = get(this.AxXY,'ylim');
            
            % xlim(2)-xlim(1) is the number of image pixels, axpos(3) is
            % the number of screen pixels
            mag = axpos(3)/(xlim(2)-xlim(1));
            
            currpixsiz = this.ImObj.PixelSize(1)/mag;
            [pixlen,physlen] = this.ScaleBarInfo.getLengths(currpixsiz);

            axlen = pixlen/mag;

            visrect = [xlim(1),ylim(1),xlim(2)-xlim(1),ylim(2)-ylim(1)];

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

            this.ScaleHandle = line('parent',this.AxXY,...
                'xdata',leftpos+[0,axlen],'ydata',vpos+[0,0],...
                'linestyle','-','color',this.ScaleBarInfo.Colour,...
                'linewidth',this.ScaleBarInfo.Thickness);
            
            
            this.ScaleText = text('parent',this.AxXY,...
                'position',[leftpos + 0.3*axlen,vpos+textoffset],...
                'FontSize',16,'String',sprintf('%d \\mum',physlen),...
                'Color',this.ScaleBarInfo.Colour);
            
        end
    end
end
