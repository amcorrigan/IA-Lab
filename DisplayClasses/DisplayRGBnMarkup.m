classdef DisplayRGBnMarkup < DisplayRGB

    properties
        hButtonOriginal
        hButtonResult
        
        FlagRaw = true; %-- Default to show row Image
    end

    methods
        function this = DisplayRGBnMarkup(parenth)

            this = this@DisplayRGB(parenth);
        end
      
        function varargout = showImage(this,imObj)

            if nargin>1
                this.ImObj = imObj;
            end

            if ~isempty(this.ImObj)

                if isempty(this.AxHandle)
                    this.setupDisplay();
                end

                
                if isempty(this.ImObj.ImDataResult)
                    cdata = this.ImObj.ImData;
                    this.FlagRaw = true;
                else
                    cdata = this.ImObj.ImDataResult;
                    this.FlagRaw = false;
                end

                if isempty(this.hSP)
                    this.ImgHandle = imagesc(cdata, 'parent',this.AxHandle);

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
                    
%                     for i = 1:10
%                         set(this.ImgHandle,'AlphaData',i*0.1);
%                         drawnow();
%                         pause(0.001);
%                     end;
                    
                    api.setImageButtonDownFcn(@this.buttondownfun);
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

        function setupDisplay(this)
            
            vboxHolder = uix.VBox('parent',this.ParentHandle);

            hTopPanel = uipanel('Parent', vboxHolder, 'units','normalized');
            set(hTopPanel,'Position',[0 0 1 1]);
            
            %-- 1. The top portion to show image
            this.AxHandle = axes('parent',hTopPanel,...
                                 'activepositionproperty','position','position',[0,0,1,1],...
                                 'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal');
            axis(this.AxHandle,'ij');

            %-- 2. The bottom bit
            %--  Add toolbar for user to choose to show results or raw
            %--  images
            hBottomBox = uix.HBox('parent',vboxHolder);

            %-- this is only a gap filler
            uix.Empty('parent',hBottomBox);
                  
            this.hButtonOriginal = uicontrol('parent',hBottomBox,...
                                             'style','togglebutton',...
                                             'units','pix',...
                                             'string', 'Original',...
                                             'Callback', @this.setShowRaw);
              
            %-- this is only a gap filler
            uix.Empty('parent',hBottomBox);
                  
            this.hButtonResult = uicontrol('parent',hBottomBox,...
                                           'style','togglebutton',...
                                           'units','pix',...
                                           'string', 'Result',...
                                           'Callback', @this.setShowResult);
              
            %-- this is only a gap filler
            uix.Empty('parent',hBottomBox);

            set(hBottomBox,'widths',[-1 80 24 80 -1]);
            set(vboxHolder,'heights',[-1,40]);
        end
      
        function setShowRaw(this, src, evt)
            if this.FlagRaw == false
                this.FlagRaw = true;
                
                api = iptgetapi(this.hSP);
                api.replaceImage(this.ImObj.ImData,'PreserveView',true);
            end
        end
        
        function setShowResult(this, src, evt)
            if this.FlagRaw == true && ~isempty(this.ImObj.ImDataResult)
                this.FlagRaw = false;
                
                api = iptgetapi(this.hSP);
                api.replaceImage(this.ImObj.ImDataResult,'PreserveView',true);
            end;
        end
        
    end
end
