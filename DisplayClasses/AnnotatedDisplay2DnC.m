classdef AnnotatedDisplay2DnC < Display2DnC
    % Basic display for overlaying segmentation results over images
    % 
    % Take the patch overlay and merge it into the standard Display2DnC
    % implementation
    
    properties
        LabelShowCheckBoxes
        
        PatchHandles = {};
        
        BuiltInLabelMaps = {jet(256),summer(256),autumn(256),'custom'};
        LabelMaps = {};
        
    end
    methods
        function this = AnnotatedDisplay2DnC(varargin)
            this = this@Display2DnC(varargin{:});
            
            
        end
        
        function varargout = showImage(this,varargin)
            % call the superclass first
            temp = showImage@Display2DnC(this,varargin{:});
            
            % then add the overlay
            if isempty(this.PatchHandles) || nargin>1
                this.plotOverlay();
            end
            
            if nargout>0
                varargout{1} = temp;
            end
        end
        
        function populateColourmaps(this)
            % Override the normal image version of this, so that the rest
            % of showImage can be used normally..
            
            % not ideal that there isn't a common method for the number of
            % image channels
            if isa(this.ImObj,'cAnnotatedImage')
                numImChan = this.ImObj.ImObj.getNumChannel();
            else
                numImChan = this.ImObj.getNumChannel();
            end
            
            totnumchan = this.ImObj.getNumChannel();
            
            % populate the default colourmap with the image objects
            % native colour
            this.ColourMaps = cell(numImChan,1);
            this.LabelMaps  = cell(totnumchan-numImChan,1);
            % this is where the current maps will be stored - empty
            % means recalculate
            this.UseMaps = cell(totnumchan,1);

            for ii = 1:numImChan
                this.ColourMaps{ii} = [this.ImObj.getNativeColour(ii),this.BuiltInMaps(:)'];
                this.CurrMap(ii) = 1; % use native colour.
            end
            
            for ii = (numImChan+1):totnumchan
                this.LabelMaps{ii-numImChan} = [this.ImObj.getNativeColour(ii),this.BuiltInLabelMaps(:)'];
                this.CurrMap(ii) = 1; % use native colour.
            end
        end
        
        
        function plotOverlay(this)
            % probably want a method to check for this..
            if isempty(this.ImObj.LabelObj)
                return
            end
            
            if ~isempty(this.PatchHandles)
                % want to delete any preexisting patchs
                warning('patch replacement not completed yet')
            end
            
            % now the bxy-getting part should be shipped to the label
            % interface, which will be referenced by the annotated image
            % method.
            
            % Within the display class, this should look like:
            % this.PatchHandles = this.ImObj.showAnnotation(cmaps,parenth)
            
            % And everything currently below will belong to the
            % showAnnotation method of the cLabel2DnC class, which will be
            % called from the AnnotatedImage class.
            usemaps = cell(numel(this.LabelMaps),1);
            numImChan = numel(this.ChannelShowCheckBoxes);
            try
            for ii = 1:numel(usemaps)
                if get(this.LabelShowCheckBoxes(ii),'value')
                    usemaps{ii} = this.LabelMaps{ii}{this.CurrMap(ii+numImChan)};
                else
                    usemaps{ii} = NaN;
                end
            end
            catch ME
                rethrow(ME)
            end
            this.PatchHandles = this.ImObj.showAnnotation(usemaps,this.AxHandle);
% %             
% %             borderXY = this.ImObj.getOutline2D();
% %             
% %             numImChan = numel(this.ChannelShowCheckBoxes);
% %             
% %             this.PatchHandles = cell(numel(borderXY),1);
% %             
% %             for ii = numel(borderXY):-1:1
% %                 if numel(borderXY{ii})>0
% %                     if get(this.LabelShowCheckBoxes(ii),'value')
% %                         
% % 
% %                         if size(this.LabelMaps{ii}{this.CurrMap(ii+numImChan)},1)==1
% %                             % single colour
% %                             try
% %                             usemap = linspace(0.25,1,255)' * this.LabelMaps{ii}{this.CurrMap(ii+numImChan)};
% %                             catch ME
% %                                 rethrow(ME)
% %                             end
% %                         else
% %                             usemap = this.LabelMaps{ii}{this.CurrMap(ii+numImChan)};
% %                         end
% % 
% %                         for jj = 1:numel(borderXY{ii})
% %                             % take the nearest colour
% %                             colidx = 1 + ceil((size(usemap,1)-1)*(jj-1)/(max(numel(borderXY{ii}),2)-1));
% %                             col = usemap(colidx,:);
% %                             this.PatchHandles{ii}(jj) = patch('xdata',borderXY{ii}{jj}(:,2),'ydata',borderXY{ii}{jj}(:,1),...
% %                                 'edgecolor',col,'facecolor',col,'parent',this.AxHandle);
% %                         end
% % 
% %                         set(this.PatchHandles{ii},'linewidth',1.5,'facealpha',0.1,...
% %                             'buttondownfcn',@this.buttondownfun)
% %                     end
% %                 end
% %             end
% %             
            for ii = 1:numel(this.PatchHandles)
                if ~isempty(this.PatchHandles{ii})
                    try
                    set(this.PatchHandles{ii},'buttondownfcn',@this.buttondownfun)
                    
                    % also need to add the context menu
                    set(this.PatchHandles{ii},'UIContextMenu',this.CxtMenu)
                    
                    catch ME
                        rethrow(ME)
                    end
                end
            end
        end
        
        function setupDisplay(this)
            this.MainVBox = uix.VBox('parent',this.ParentHandle);
            
            hPanel = uipanel('Parent', this.MainVBox, 'units','normalized');
            set(hPanel,'Position',[0 0 1 1]);
            
            this.AxHandle = axes('parent',hPanel,...
                'activepositionproperty','position','position',[0,0,1,1],...
                    'xcolor','none','ycolor','none');
            axis(this.AxHandle,'equal');
            
            
            temp = uix.HBox('parent',this.MainVBox);
            this.HideButton = uicontrol('Style','pushbutton','parent',temp,'callback',...
                @this.toggleHide,'String',char(9660));
            
            
% % %             for jj = 1:numel(this.ImCMaps)
% % %                 this.DispToolArray{jj} = uix.HBox('parent',this.MainVBox);
% % %                 for ii = 1:numel(this.ImCMaps{jj})
% % %                     if ischar(this.ImCMaps{jj}{ii})
% % % %                         tempcdata = rand(24,24,3); % for now
% % %                         tempcdata = arraySliceReference(rand(6,6,3),ceil((1:24)/4),ceil((1:24)/4)); % for now
% % %                         str = 'C';
% % %                     else
% % %                         tempcdata = repmat(permute(amcResize3D(this.ImCMaps{jj}{ii},[24,3]),[1,3,2]),[1,24,1]);
% % %                         str = '';
% % %                     end
% % %                     
% % %                     uicontrol('parent',this.DispToolArray{jj},...
% % %                       'style','pushbutton',...
% % %                       'units','pix',...
% % %                       'cdata', tempcdata, ...
% % %                       'string', str,...
% % %                       'Callback', {@this.colourCallback,jj,ii,'image'});
% % %                     
% % %                 end
% % %                 this.ChannelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj},'style','checkbox',...
% % %                     'string',sprintf('Channel %d',jj),'Value',true,'callback',@(src,evt)this.showImage());
% % %             
% % %                 uix.Empty('parent',this.DispToolArray{jj});
% % %                 
% % %                 set(this.DispToolArray{jj},'widths',[24*ones(1,numel(this.ImCMaps{jj})),80,-1]);
% % %                 
% % %                 
% % %             end
            

            for jj = 1:numel(this.ColourMaps)

                this.DispToolArray{jj} = uix.HBox('parent',this.MainVBox);

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
                
                set(this.DispToolArray{jj},'widths',[80,24*ones(1,numel(this.ColourMaps{jj})),-1]);
                
            end
            
            for jj = 1:numel(this.LabelMaps)
                fullind = jj+numel(this.ColourMaps);
                this.DispToolArray{fullind} = uix.HBox('parent',this.MainVBox);
                this.LabelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{fullind},'style','checkbox',...
                    'string',sprintf('Label %d',jj),'Value',true,'callback',{@this.labelToggleCallback,jj});
            
                for ii = 1:numel(this.LabelMaps{jj})
                    if ischar(this.LabelMaps{jj}{ii})
%                         tempcdata = rand(24,24,3); % for now
                        tempcdata = arraySliceReference(rand(5,5,3),ceil((1:20)/4),ceil((1:20)/4)); % for now
                        str = 'C';
                    else
                        tempcdata = repmat(permute(amcResize3D(this.LabelMaps{jj}{ii},[20,3]),[1,3,2]),[1,20,1]);
                        str = '';
                    end
                    
                    uicontrol('parent',this.DispToolArray{fullind},...
                      'style','pushbutton',...
                      'units','pix',...
                      'cdata', tempcdata, ...
                      'string', str,...
                      'Callback', {@this.labelCallback,jj,ii});
                    
                end
                
                % add options to increase or decrease the thickness of the
                % lines
                uicontrol('parent',this.DispToolArray{fullind},'style','pushbutton','string','+',...
                    'callback',{@this.incrementLineWidth,jj,0.5});
                uicontrol('parent',this.DispToolArray{fullind},'style','pushbutton','string','-',...
                    'callback',{@this.incrementLineWidth,jj,-0.5});
                
                uicontrol('parent',this.DispToolArray{fullind},'style','slider','max',1,'min',0,...
                    'callback',{@this.adjustPatchAlpha,jj},'value',0.1);
                
                uix.Empty('parent',this.DispToolArray{fullind});
                
                set(this.DispToolArray{fullind},'widths',[80,24*ones(1,numel(this.LabelMaps{jj})),24,24,80,-1]);
                
            end
            
            try
            set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ColourMaps)+numel(this.LabelMaps))]);
            catch ME
                rethrow(ME)
            end
% %             keyboard
        end
        
        function adjustPatchAlpha(this,src,evt,idx)
            % not all labels have a facealpha property.
            % a mature solution will ship the code out to the relevant
            % label class to return the adjustment required, but for now
            % just check for the facealpha property, and if not, adjust the
            % marker size instead.
            
            handinds = find(ishandle(this.PatchHandles{idx}));
            
            if ~isempty(handinds)
                if ~isempty(findobj(this.PatchHandles{idx}(handinds),...
                        '-property','FaceAlpha'))
                    % has the facealpha property, adjust this
                    set(this.PatchHandles{idx}(handinds),'FaceAlpha',get(src,'value'));
                else
                    % no facealpha, adjust the marker size instead
                    set(this.PatchHandles{idx}(handinds),'MarkerSize',10*get(src,'value'));
                end
            end
        end
        
        function labelCallback(this,src,evt,ch,ind)
            % this callback will be different from the single channel case,
            % because the images have to be merged.
            
            % Depending on the speed, it might be worth keeping a copy of
            % the contrast-adjusted data in the class..
            numImChan = numel(this.ChannelShowCheckBoxes);
            
            if ind==numel(this.LabelMaps{ch})
                % custom colour
                temp = uisetcolor('Choose a new colour');
                if ~(numel(temp)==1 && temp==0)
                    this.LabelMaps{ch}{ind} = temp;
                end
                set(src,'cdata',bsxfun(@times,ones(24,24),reshape(this.LabelMaps{ch}{ind},[1,1,3])));
            end
            
            this.CurrMap(ch + numImChan) = ind;

            % instead of redrawing everything, try just changing
            % the appropriate colours

            if ~isempty(this.PatchHandles{ch})
% %                 if size(this.LabCMaps{ch}{ind},1)==1
% %                     % single colour
% %                     usemap = linspace(0.25,1,255)' * this.LabCMaps{ch}{ind};
% %                 else
% %                     usemap = this.LabCMaps{ch}{ind};
% %                 end
                    if size(this.LabelMaps{ch}{this.CurrMap(ch+numImChan)},1)==1
                        % single colour
                        try
                        usemap = linspace(1,0.25,255)' * this.LabelMaps{ch}{this.CurrMap(ch+numImChan)};
                        catch ME
                            rethrow(ME)
                        end
                    else
                        usemap = this.LabelMaps{ch}{this.CurrMap(ch+numImChan)};
                    end

                for jj = 1:numel(this.PatchHandles{ch})
                    colidx = 1 + ceil((size(usemap,1)-1)*(jj-1)/(max(numel(this.PatchHandles{ch}),2)-1));
                    col = usemap(colidx,:);
                    if ~isempty(findobj(this.PatchHandles{ch}(jj),...
                            '-property','EdgeColor'))
                        % has the EdgeColor property, it's a patch
                        set(this.PatchHandles{ch}(jj),'edgecolor',col,'facecolor',col)
                    else
                        % no edgecolor, adjust the marker color instead
                        set(this.PatchHandles{ch}(jj),'color',col);
                    end
                    
                end


            end
        end
        
        function incrementLineWidth(this,src,evt,idx,amt)
            if nargin<4 || isempty(amt)
                amt = 0.5;
            end
            
            handinds = find(ishandle(this.PatchHandles{idx}));
            
            if ~isempty(handinds)
                currwid = get(this.PatchHandles{idx}(handinds(1)),'LineWidth');
                
                newwid = max(0.5,currwid+amt);
                
                set(this.PatchHandles{idx}(handinds),'LineWidth',newwid);
            end
        end
        
        function labelToggleCallback(this,src,evt,idx)
            % check for if it's currently visible
            handinds = find(ishandle(this.PatchHandles{idx}));
            if isempty(handinds)
                return
            end
            
            if strcmpi(get(this.PatchHandles{idx}(handinds(1)),'Visible'),'on')
                % currently visible, remove
                set(this.PatchHandles{idx}(handinds),'Visible','off')
            else
                % make visible again
                set(this.PatchHandles{idx}(handinds),'Visible','on')
            end
        end
        
    end
end
