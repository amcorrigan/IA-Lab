classdef CombineImagePoints < QCViewer
    properties
        BgImage
        FgXYZ
        
        ImgHandle
        PointHandles
        Marker = 'o';

        ParentH

        AxHandle
        MainVBox
        MainHBox
        
        ZCMap
        ZDim
    end
    methods
        function this = CombineImagePoints(fg,bg,parenth)
            % rather than bw and image, use fg and bg so that it isn't limited to
            % thresholded images
            if nargin<3 || isempty(parenth)
                parenth = figure();
            end
            this.ParentH = parenth;

            this.MainVBox = uix.VBox('parent',this.ParentH);
            this.MainHBox = uix.HBox('parent',this.MainVBox); % preparing to add extra content in sub-classes

            this.AxHandle = axes('parent',this.MainHBox);
            
            
            this.ZDim = size(bg,3);
            if this.ZDim>1
                bg = compress3D(bg,'max');
            end
            
            this.BgImage = bg;
            this.FgXYZ = fg;
            
% %             this.ZCMap = interp1q((1:6)',[1,0,0;1,0,0;0,1,0;0,1,0;0,0,1;0,0,1],linspace(1,6,20)');
            this.ZCMap = interp1q((1:3)',[1,0,0;0,1,0;0,0,1],linspace(1,3,20)');
            
            this.PointHandles = [];
            
            this.updateView();
        end

        function updateFg(this,newfg)
            % newfg should be a list of coordinates
            this.FgXYZ = newfg;

            this.updateView();
        end

        function updateView(this,src,evt)
            % this should also work fine for RGB data
            
            if ~isempty(this.ImgHandle)
                xlim = get(this.AxHandle,'xlim');
                ylim = get(this.AxHandle,'ylim');
                
                set(this.ImgHandle,'cdata',this.BgImage);
                % check that this doesn't change the axes limits
            else
                this.ImgHandle = imagesc(this.BgImage);
                colormap(this.AxHandle,'gray')
                hold(this.AxHandle,'on')
                xlim = get(this.AxHandle,'xlim');
                ylim = get(this.AxHandle,'ylim');
                
            end
            
            % then overlay the points
            % try 20 different colours to begin with
            numcolours = size(this.ZCMap,1);
            
            % set up the plot handles if this hasn't been done yet
            if isempty(this.PointHandles)
                for ii = 1:numcolours
                    this.PointHandles(ii) = plot(this.AxHandle,NaN,NaN,this.Marker,...
                        'color',this.ZCMap(ii,:));
                    
                end
            end
            
            if size(this.FgXYZ,2)>2
                colgroup = max(1,min(numcolours,ceil(this.FgXYZ(:,3)/this.ZDim)));
            else
                colgroup = ceil(numcolours/2)*ones(size(this.FgXYZ,1),1);
            end
            
            try
            for ii = 1:numcolours
                if isempty(this.FgXYZ) || nnz(colgroup==ii)==0
                    set(this.PointHandles(ii),'xdata',NaN,'ydata',NaN);
                else
                    set(this.PointHandles(ii),'xdata',this.FgXYZ(colgroup==ii,2),...
                        'ydata',this.FgXYZ(colgroup==ii,1));
                end
            end
            catch ME
                rethrow(ME)
            end
%             set(this.AxHandle,'xlim',[1,size(this.BgImage,2)],'ylim',[1,size(this.BgImage,1)]);
            set(this.AxHandle,'xlim',xlim,'ylim',ylim)
                
        end

    end
    
end

    