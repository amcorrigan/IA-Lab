classdef cPatchAnnotatedDisplay2D < cCurvesAnnotatedDisplay2D
    % Basic display for overlaying segmentation results over images
    % 
    % This is the basic implementation, whereby everything is recalculated
    % after a change (of contrast, colour, toggle display)
    % TODO - It might be faster to hold copies of each layer, so that only the
    % part that gets changed is recalculated before stacking
    
    properties
        
    end
    methods
        function this = cPatchAnnotatedDisplay2D(varargin)
            this = this@cCurvesAnnotatedDisplay2D(varargin{:});
        end
        
        function plotOverlay(this)
            if isempty(this.AnObj.LabelObj)
                return
            end
            
            % this is quite complicated just to avoid using a for loop..
            idata = arrayfun(@(x,y)x*y{1},...
                this.AnObj.LabelObj.NumLabels,getData2D(this.AnObj.LabelObj),...
                'uniformoutput',false);
%             idata = this.AnObj.LabelObj.NumLabels*getData2D(this.AnObj.LabelObj); % already shuffles the data
            if ~iscell(idata)
                idata = {idata};
            end
            
            this.PatchHandles = cell(numel(idata),1);
            
            for ii = numel(idata):-1:1
                if max(idata{ii}(:)>0)
                    if get(this.LabelShowCheckBoxes(ii),'value')
                        bxy = label2outline(idata{ii},8,8);

                        if size(this.LabCMaps{ii}{this.CurrLabMap(ii)},1)==1
                            % single colour
                            try
                            usemap = linspace(0.25,1,255)' * this.LabCMaps{ii}{this.CurrLabMap(ii)};
                            catch ME
                                rethrow(ME)
                            end
                        else
                            usemap = this.LabCMaps{ii}{this.CurrLabMap(ii)};
                        end

                        for jj = 1:numel(bxy)
                            % take the nearest colour
                            colidx = 1 + ceil((size(usemap,1)-1)*(jj-1)/(max(numel(bxy),2)-1));
                            col = usemap(colidx,:);
                            this.PatchHandles{ii}(jj) = patch('xdata',bxy{jj}(:,2),'ydata',bxy{jj}(:,1),...
                                'edgecolor',col,'facecolor',col,'parent',this.AxHandle);
                        end

                        set(this.PatchHandles{ii},'linewidth',1.5,'facealpha',0.2)
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
            
            
            for jj = 1:numel(this.ImCMaps)
                this.DispToolArray{jj} = uix.HBox('parent',this.MainVBox);
                for ii = 1:numel(this.ImCMaps{jj})
                    if ischar(this.ImCMaps{jj}{ii})
%                         tempcdata = rand(24,24,3); % for now
                        tempcdata = arraySliceReference(rand(6,6,3),ceil((1:24)/4),ceil((1:24)/4)); % for now
                        str = 'C';
                    else
                        tempcdata = repmat(permute(amcResize3D(this.ImCMaps{jj}{ii},[24,3]),[1,3,2]),[1,24,1]);
                        str = '';
                    end
                    
                    uicontrol('parent',this.DispToolArray{jj},...
                      'style','pushbutton',...
                      'units','pix',...
                      'cdata', tempcdata, ...
                      'string', str,...
                      'Callback', {@this.colourCallback,jj,ii,'image'});
                    
                end
                this.ChannelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj},'style','checkbox',...
                    'string',sprintf('Channel %d',jj),'Value',true,'callback',@(src,evt)this.showImage());
            
                uix.Empty('parent',this.DispToolArray{jj});
                
                set(this.DispToolArray{jj},'widths',[24*ones(1,numel(this.ImCMaps{jj})),80,-1]);
                
                
            end
            for jj = 1:numel(this.LabCMaps)
                this.DispToolArray{jj + numel(this.ImCMaps)} = uix.HBox('parent',this.MainVBox);
                for ii = 1:numel(this.LabCMaps{jj})
                    if ischar(this.LabCMaps{jj}{ii})
%                         tempcdata = rand(24,24,3); % for now
                        tempcdata = arraySliceReference(rand(6,6,3),ceil((1:24)/4),ceil((1:24)/4)); % for now
                        str = 'C';
                    else
                        tempcdata = repmat(permute(amcResize3D(this.LabCMaps{jj}{ii},[24,3]),[1,3,2]),[1,24,1]);
                        str = '';
                    end
                    
                    uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},...
                      'style','pushbutton',...
                      'units','pix',...
                      'cdata', tempcdata, ...
                      'string', str,...
                      'Callback', {@this.colourCallback,jj,ii,'label'});
                    
                end
                this.LabelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','checkbox',...
                    'string',sprintf('Label %d',jj),'Value',true,'callback',{@this.labelToggleCallback,jj});
            
                % add options to increase or decrease the thickness of the
                % lines
                uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','pushbutton','string','+',...
                    'callback',{@this.incrementLineWidth,jj,0.5});
                uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','pushbutton','string','-',...
                    'callback',{@this.incrementLineWidth,jj,-0.5});
                
                uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','slider','max',1,'min',0,...
                    'callback',{@this.adjustPatchAlpha,jj},'value',0.2);
                
                uix.Empty('parent',this.DispToolArray{jj + numel(this.ImCMaps)});
                
                set(this.DispToolArray{jj + numel(this.ImCMaps)},'widths',[24*ones(1,numel(this.LabCMaps{jj})),80,24,24,80,-1]);
                
            end
            
            set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ImCMaps)+numel(this.LabCMaps))]);

        end
        
        function adjustPatchAlpha(this,src,evt,idx)
            
            handinds = find(ishandle(this.PatchHandles{idx}));
            
            if ~isempty(handinds)
                set(this.PatchHandles{idx}(handinds),'FaceAlpha',get(src,'value'));
            end
        end
        
        function colourCallback(this,src,evt,ch,ind,type)
            % this callback will be different from the single channel case,
            % because the images have to be merged.
            
            % Depending on the speed, it might be worth keeping a copy of
            % the contrast-adjusted data in the class..
            
            switch type
                case 'image'
                    if ind==numel(this.ImCMaps{ch})
                        % custom colour
                        this.ImCMaps{ch}{ind} = uisetcolor('Choose a new colour');
                        set(src,'cdata',bsxfun(@times,ones(24,24),reshape(this.ImCMaps{ch}{ind},[1,1,3])));
                    end
                    this.CurrImMap(ch) = ind;
                    
                    
                    if ishandle(this.ImgHandle)
                        cdata = calculateImage(this);
                        set(this.ImgHandle,'cdata',cdata);
                    end
            
                case 'label'
                    if ind==numel(this.LabCMaps{ch})
                        % custom colour
                        this.LabCMaps{ch}{ind} = uisetcolor('Choose a new colour');
                        set(src,'cdata',bsxfun(@times,ones(24,24),reshape(this.LabCMaps{ch}{ind},[1,1,3])));
                    end
                    this.CurrLabMap(ch) = ind;
                    
                    % instead of redrawing everything, try just changing
                    % the appropriate colours
                    
                    if ~isempty(this.PatchHandles{ch})
                        if size(this.LabCMaps{ch}{ind},1)==1
                            % single colour
                            usemap = linspace(0.25,1,255)' * this.LabCMaps{ch}{ind};
                        else
                            usemap = this.LabCMaps{ch}{ind};
                        end
                        
                        for jj = 1:numel(this.PatchHandles{ch})
                            colidx = 1 + ceil((size(usemap,1)-1)*(jj-1)/(max(numel(this.PatchHandles{ch}),2)-1));
                            col = usemap(colidx,:);
                            set(this.PatchHandles{ch}(jj),'edgecolor',col,'facecolor',col)
                        end
                    
                        
                    end
            end
            
        end
    end
end
