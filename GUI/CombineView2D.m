classdef CombineView2D < QCViewer
    % One of the styles of viewing for parameter tuning and/or QC
    % start off by storing the foreground image and the threshold, and calculating the
    % binary image here.  This means that it necessarily is limited to thresholded images
    properties

        FgImage
        BgImage

        ImgHandle

        ParentH

        AxHandle
        SlidHandle
        MainVBox
        MainHBox % preparing for sub classes

    end

    methods
        function this = CombineView2D(fg,bg,parenth)
            % rather than bw and image, use fg and bg so that it isn't limited to
            % thresholded images
            if nargin<3 || isempty(parenth)
                parenth = figure();
            end
            this.ParentH = parenth;

            this.MainVBox = uix.VBox('parent',this.ParentH);
            this.MainHBox = uix.HBox('parent',this.MainVBox); % preparing to add extra content in sub-classes

            this.AxHandle = axes('parent',this.MainHBox);

            this.SlidHandle = uicontrol('parent',this.MainVBox,'style','slider',...
              'max',1,'min',0,'value',0.5,'sliderstep',[0.1,1],'callback',@this.updateView);
            
            set(this.MainVBox,'heights',[-1,30])
            
            % this range normalisation might interfere with some of the display, watch out for this
            % the other option is for the calling function to take care of this, that
            % might be a better option.
            this.BgImage = rangeNormalise(bg);
            this.FgImage = rangeNormalise(fg);
            if size(bg,3)>1
                bg = compress3D(bg,'max');
            end
            if size(fg,3)>1
                fg = compress3D(fg,'max');
            end
            
            if any(size(fg)~=size(bg))
                % bg needs to be scaled to the size of fg
                % (since it's more likely that the processed image will
                % have been downscaled)
                bg = imresize(bg,[size(fg,1),size(fg,2)],'bilinear');
            end
                    
            this.BgImage = bg;
            this.FgImage = fg;

            this.updateView();
        end

        function updateFg(this,newfg)
            newfg = rangeNormalise(newfg);
            if size(newfg,3)>1
                newfg = compress3D(newfg,'max');
            end
            
            this.FgImage = newfg;
            
            this.updateView();
        end

        function updateView(this,src,evt)
            % this should also work fine for RGB data, as long both as like
            % this
            
            frac = get(this.SlidHandle,'Value');
            newcdata = frac*this.FgImage + (1-frac)*this.BgImage;

            if ~isempty(this.ImgHandle)
                set(this.ImgHandle,'cdata',newcdata);
                % check that this doesn't change the axes limits
            else
                this.ImgHandle = imagesc(newcdata);
                colormap(this.AxHandle,'gray')
                
            end
        end

    end
end
