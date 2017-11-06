classdef ImageWorkspace < handle
    properties
        MainHBox
        ControlVBox
        PanelHandle
        ImObjList = {}
        ThumbnailList = {}
        
        LoaderButton
        HelpButton
        
        ImhArray
        
        AxHandle
        
        RowLength = 5;
    end
    properties (Dependent)
        NumImages
    end
    events
        displayFromWorkspace
        directBank
    end
    methods
        function this = ImageWorkspace(parenth)
            this.MainHBox = uix.HBox('parent',parenth);
            
            this.ControlVBox = uix.VBox('parent',this.MainHBox);
            
            %________________________
            % Loader button
            icon = im2double(imresize(imread('yokocurvearrow.png'),[20,20]));
            icon(repmat(all(icon>0.92,3),[1,1,size(icon,3)])) = NaN;
            
            
            this.LoaderButton = uicontrol('parent',this.ControlVBox,...
                'String','','callback',@this.loadercallback,...
                'cdata',icon);
            
            
            
            uix.Empty('parent',this.ControlVBox);
            this.HelpButton = uicontrol('parent',this.ControlVBox,...
                'String','?','callback',@this.helpcallback);
            set(this.ControlVBox,'heights',[24,-1,24])
            
            this.PanelHandle = uix.BoxPanel('parent',this.MainHBox,'Title','Test Images',...
                'TitleColor',[0.3,1,0.8]);
            this.AxHandle = axes('parent',this.PanelHandle,'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal')
            set(this.AxHandle,'units','normalized','activepositionproperty','position',...
                'position',[0,0,1,1],'visible','off','ydir','reverse')
            
            set(this.MainHBox,'widths',[24,-1]);
        end
        
        function addImage(this,imobj,cdata)
            % the image to be added is an object, while the cdata is the
            % thumbnail
            
            this.ImObjList = [this.ImObjList;{imobj}];
            
            if size(cdata,3)==1
                cdata = bsxfun(@times,cdata,cat(3,1,1,1));
            end
            this.ThumbnailList = [this.ThumbnailList;{cdata}];
            
            refreshDisplay(this)
        end
        
        function refreshDisplay(this)
            % display the thumbnails individually so that they can be
            % clicked on easily
            
            delete(this.ImhArray)
            this.ImhArray = [];
            
            mainfig = getFigParent(this.MainHBox);
            
            for ii = 1:numel(this.ImObjList)
                rowi = ceil(ii/this.RowLength);
                coli = mod(ii-1,this.RowLength)+1;
                this.ImhArray(ii) = imagesc('ydata',rowi+[-0.95,-0.05],'xdata',coli+[-0.95,-0.05],...
                    'cdata',this.ThumbnailList{ii},'parent',this.AxHandle);
%                 set(this.ImhArray(ii),'buttondownfcn',{@this.showInfo,ii})
                tempm = uicontextmenu(mainfig);
                uimenu(tempm,'label','Show Information','callback',{@this.showInfo,ii});
                uimenu(tempm,'label','Display in main window','callback',{@this.showInMain,ii});
                uimenu(tempm,'label','Remove','callback',{@this.remove,ii});
                
                set(this.ImhArray(ii),'uicontextmenu',tempm);
                
            end
            
            set(this.AxHandle,'xlim',[0,min(max(1,numel(this.ImObjList)),this.RowLength)],...
                'ylim',[0,max(1,ceil(numel(this.ImObjList)/this.RowLength))])
            
            
        end
        
        function n = get.NumImages(this)
            n = numel(this.ImObjList);
        end
        
        function showInfo(this,src,evt,ind)
            IAHelp()
        end
        function showInMain(this,src,evt,ind)
            % pass the image back to the display as event data
            data = GenEvtData(this.ImObjList{ind});
            notify(this,'displayFromWorkspace',data)
        end
        function remove(this,src,evt,ind)
            this.ImObjList(ind) = [];
            this.ThumbnailList(ind) = [];
            refreshDisplay(this)
        end
        
% %         function N = getNumImage(this)
% %             N = numel(this.ImObjList);
% %         end
        
        function delete(this)
%             delete(this.PanelHandle)  
            delete(this.MainHBox)
        end
        
        function loadercallback(this,src,evt)
            % Get the image directly from the loader rather than from the
            % display (saves reading things in unnecessarily)
            notify(this,'directBank')
        end
        
        function helpcallback(this,src,evt)
            % display some help about how to use this (and possible
            % feedback on improvements)
            
            
        end
    end
end