classdef DisplayRGB < cDisplayInterface

    properties
        ParentHandle % the handle of the containing graphics object

        FigParent % Useful to store a direct reference to the parent figure, for handling callbacks
        AxHandle
        ImgHandle = [];

        MainVBox

        ImObj

        CxtMenu

        ChannelShowCheckBoxes

        hSP=[];
        hOvPanel = [];

        PrevMousePosition
    end

    methods
        function this = DisplayRGB(parenth)

            this.ParentHandle = parenth;
            aHandle = this.ParentHandle;
            while isa(aHandle, 'matlab.ui.Figure') == 0
                aHandle = aHandle.Parent;
            end
            this.FigParent = aHandle;

            %%  Context menu (right click)
            %-- If the current parent uiControl is NOT a figure, go ask its parent

            this.CxtMenu = uicontextmenu(this.FigParent);
            uimenu(this.CxtMenu,'label','Zoom in', 'CallBack', {@this.contextcallback, 'Zoom in'});
            uimenu(this.CxtMenu,'label','Zoom out', 'CallBack', {@this.contextcallback, 'Zoom out'});
            uimenu(this.CxtMenu,'label','Fit the window', 'CallBack', {@this.contextcallback, 'Fit the window'});
        end
      
        function varargout = showImage(this,imObj)

            if nargin>1
                this.ImObj = imObj;
            end

            if ~isempty(this.ImObj)

                if isempty(this.AxHandle)
                    setupDisplay(this);
                end

                cdata = this.ImObj.ImData;

                if isempty(this.hSP)
                    this.ImgHandle = imshow(cdata, 'parent',this.AxHandle);

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%________________________________________________
                    %%  Scroll Panel for panning
                    this.hSP = imscrollpanel(this.AxHandle.Parent, this.ImgHandle);

                    set(this.hSP, 'Units','normalized','Position',[0 0 1 1]);
                    set(this.hSP.Children(2),'BackgroundColor',[0 0 0]);
                    set(this.hSP.Children(3),'BackgroundColor',[0 0 0]);

                    api = iptgetapi(this.hSP);
                    api.setMagnification(api.findFitMag());
                    %%________________________________________________

                    this.ImgHandle.UIContextMenu = this.CxtMenu;
                    this.hSP.UIContextMenu = this.CxtMenu;

                    this.hOvPanel = imoverviewpanel(this.AxHandle.Parent, this.ImgHandle);

                    set(this.hOvPanel,'Units','Normalized', 'Position',[0.85 0.85 0.15 0.15],...
                        'BackgroundColor', [1 1 1], 'BorderType', 'beveledin', 'BorderWidth', 3);

                    %%________________________________________________
                    %%  Magnification info
                    immagbox(this.AxHandle.Parent, this.ImgHandle);

                    api.setImageButtonDownFcn(@this.buttondownfun)
                else
                    api = iptgetapi(this.hSP);
                    api.replaceImage(cdata,'PreserveView',true);
                end

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

        function setupDisplay(this)
            this.MainVBox = uix.VBox('parent',this.ParentHandle);

            hPanel = uipanel('Parent', this.MainVBox, 'units','normalized');
            set(hPanel,'Position',[0 0 1 1]);

            this.AxHandle = axes('parent',hPanel,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal');
            axis(this.AxHandle,'ij');
        end

        function imObj = getImObj(this)
            % seems trivial, but required for other viewers
            imObj = this.ImObj;
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
            end
        end
    end
end
