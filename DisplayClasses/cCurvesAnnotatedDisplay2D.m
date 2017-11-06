classdef cCurvesAnnotatedDisplay2D < cDisplayInterface
    % Basic display for overlaying segmentation results over images
    
    % This is the basic implementation, whereby everything is recalculated
    % after a change (of contrast, colour, toggle display)
    % TODO - It might be faster to hold copies of each layer, so that only the
    % part that gets changed is recalculated before stacking
    
    properties
        ParentHandle % the handle of the containing graphics object
        AxHandle
        ImgHandle = [];
        PatchHandles = {};
        
        MainVBox
        HideButton
        DispToolArray = {};
        
        % placeholder for being able to pass information (axes limits,
        % colourmap, etc) from an existing display
        % it's not been used yet, but I think it should be part of the
        % interface (passed in the constructor) for future functionality
        setupInfo = [];
        
        AnObj % altered to be clear that it's an annotated object
        
        ConObj
        
        ImCMaps = {}
        LabCMaps = {}
        
        ImageMapsBuiltIn = {[1,0,0],[0,1,0],[0,0,1],'custom'};
        LabelMapsBuiltIn = {jet(256),parula(256),summer(256),'custom'};
        
        CurrImMap % the current selection for each channel
        CurrLabMap
        
        ChannelShowCheckBoxes
        LabelShowCheckBoxes
        
        % standard row of colour choices that will be built in to each channel
        
%         ContrastLstnr % listener for contrast adjustment
        % it might make sense to move the listener outside of the display
        % into DisplayManager, so that only one event is triggered for
        % all the displays
        % then requires a manager class, which can be created by the
        % display if one isn't supplied.
    end
    methods
        function this = cCurvesAnnotatedDisplay2D(parenth,contrastObj,info)
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
        end
        
        function varargout = showImage(this,imObj)
            
            if nargin>1
                this.AnObj = imObj;
                
            end
            
            if isempty(this.ImCMaps) && ~isempty(this.AnObj)
                % populate the default colourmap with the image objects
                % native colour
                % currently, the annotated image class doesn't have a
                % mechanism for directly referencing a label or an image
                % part, they have to be obtained from the contained
                % individual classes
                % this isn't necessarily a problem, if this class is only
                % used for annotated images - because it's a slightly
                % different interface: images don't need a getLabel method,
                % etc..
                % A solution to this would be to have the label interface
                % have getLabel rather than getData methods, and the image
                % interface needs getImData, and then the getData method of
                % each would simply call the appropriate method
                % Quite inelegant if the annotated image isn't used all
                % that much... Something to try out in the next version..
                
                % for now, directly call the stored image and label objects
                
                this.ImCMaps = cell(this.AnObj.ImObj.NumChannel,1);
                for ii = 1:numel(this.ImCMaps)
                    this.ImCMaps{ii} = [this.AnObj.ImObj.getNativeColour(ii),this.ImageMapsBuiltIn(:)'];
                    this.CurrImMap(ii) = ii + 1; % don't use native colour just yet, haven't extracted from parser.
                end
                
                this.LabCMaps = cell(this.AnObj.LabelObj.NumChannel,1);
                for ii = 1:numel(this.LabCMaps)
                    this.LabCMaps{ii} = [this.AnObj.LabelObj.getNativeColour(ii),this.LabelMapsBuiltIn(:)'];
                    this.CurrLabMap(ii) = ii + 1; % don't use native colour just yet, haven't extracted from parser.
                    
                end
                    
            end
            if ~isempty(this.AnObj)
                
                if isempty(this.AxHandle)
                    setupDisplay(this);
                end
                if ~isempty(this.ImgHandle)
                    delete(this.ImgHandle)
                end
                if ~isempty(this.PatchHandles)
                    cellfun(@(x)delete(x(ishandle(x))),this.PatchHandles)
                    this.PatchHandles = {};
                end

                % cdata = uint16(imObj.getRGB2D()); % currently double to provide automatic scaling?
                
                % the contrast adjustment is likely to return a double anyway
                % for consistency.
                
                cdata = calculateImage(this);
                
                this.ImgHandle = imagesc('parent',this.AxHandle,'cdata',cdata);
                
                plotOverlay(this);
                
                % only do this if it hasn't been done already?
                if strcmpi(get(this.AxHandle,'XLimMode'),'auto')
                    set(this.AxHandle,'xlim',[0,this.AnObj.ImObj.SizeY],'ylim',[0,this.AnObj.ImObj.SizeX])
                end
            else
                this.ImgHandle = NaN;
            end
            
            if nargout>0
                % probably want to be able to get the contrast object if
                % there is one, to save constrast for subsequent viewings
                varargout{1} = this.ImgHandle;
            end
            
        end
        
% %         function cdata = calculateOverlaidImage(this)
% %             
% %             cdata = calculateImage(this);
% % 
% %             [ldata,maskdata] = calculateLabelOverlay(this);
% %             
% %             % then add the labeldata over the top of the cdata
% %             for ii = 1:numel(ldata)
% %                 if ~isempty(ldata{ii})
% %                     cdata = bsxfun(@times,cdata,1-maskdata{ii}) + bsxfun(@times,ldata{ii},maskdata{ii});
% %                 end
% %             end
% % 
% %         end
        
        function cdata = calculateImage(this)
            % this part is basically the same as the image display, but
            % references the contained object instead
            
            % data is returned as cell array of double, which should be
            % fine for contrast adjustment
            pdata = process(this.ConObj,this.AnObj.ImObj.getDataC2D()); % getRGB2D already converts to double
            
            % then need to build the RGB display based on which channels
            % are visible
            cdata = zeros(size(pdata{1},1),size(pdata{1},2),3);
            
            for ii = 1:numel(this.ImCMaps)
                if get(this.ChannelShowCheckBoxes(ii),'value')
                    useMap = this.ImCMaps{ii}{this.CurrImMap(ii)};
                    if size(useMap,1)==1
                        % single colour, don't need to call ind2rgb
                        if nnz(useMap)==1
                            % only r g or b is used, might be able to speed
                            % up further
                            col = find(useMap);
                            cdata(:,:,col) = max(cdata(:,:,col),useMap(col)*pdata{ii});
                        else
                            cdata = max(cdata,bsxfun(@times,pdata{ii},reshape(useMap,[1,1,3])));
                        end
                    else
                        % colormap
                        try
                            
                            cdata = max(cdata,ind2rgb(uint8(255*pdata{ii}),useMap));
                        catch ME
                            rethrow(ME)
                        end
                        
                    end
                end
            end
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
            
            for ii = 1:numel(idata)
                if max(idata{ii}(:)>0)
                    
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
                            'edgecolor',col,'facecolor','none','parent',this.AxHandle);
                    end

                    set(this.PatchHandles{ii},'linewidth',1.5)
                    if ~get(this.LabelShowCheckBoxes(ii),'value')
                        set(this.PatchHandles{ii},'visible','off')
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
                    try
                    uicontrol('parent',this.DispToolArray{jj},...
                      'style','pushbutton',...
                      'units','pix',...
                      'cdata', tempcdata, ...
                      'string', str,...
                      'Callback', {@this.colourCallback,jj,ii,'image'});
                    catch ME
                        rethrow(ME)
                    end
                end
                this.ChannelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj},'style','checkbox',...
                    'string',sprintf('Channel %d',jj),'Value',true,'callback',@(src,evt)this.showImage());
            
                uix.Empty('parent',this.DispToolArray{jj});
                try
                set(this.DispToolArray{jj},'widths',[24*ones(1,numel(this.ImCMaps{jj})),80,-1]);
                catch ME
                    rethrow(ME)
                end
                
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
                    try
                    uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},...
                      'style','pushbutton',...
                      'units','pix',...
                      'cdata', tempcdata, ...
                      'string', str,...
                      'Callback', {@this.colourCallback,jj,ii,'label'});
                    catch ME
                        rethrow(ME)
                    end
                end
                this.LabelShowCheckBoxes(jj) = uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','checkbox',...
                    'string',sprintf('Label %d',jj),'Value',true,'callback',{@this.labelToggleCallback,jj});
            
                % add options to increase or decrease the thickness of the
                % lines
                uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','pushbutton','string','+',...
                    'callback',{@this.incrementLineWidth,jj,0.5});
                uicontrol('parent',this.DispToolArray{jj + numel(this.ImCMaps)},'style','pushbutton','string','-',...
                    'callback',{@this.incrementLineWidth,jj,-0.5});
                
                uix.Empty('parent',this.DispToolArray{jj + numel(this.ImCMaps)});
                
                try
                set(this.DispToolArray{jj + numel(this.ImCMaps)},'widths',[24*ones(1,numel(this.LabCMaps{jj})),80,24,24,-1]);
                catch ME
                    rethrow(ME)
                end
                
            end
            
            set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ImCMaps)+numel(this.LabCMaps))]);

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
        
        function toggleHide(this,src,evt)
            if isempty(get(this.DispToolArray{1},'parent'))
                % needs to be reattached
                for ii = 1:numel(this.DispToolArray)
                    set(this.DispToolArray{ii},'parent',this.MainVBox)
                end
                set(this.HideButton,'string',char(9660))
                set(this.MainVBox,'heights',[-1,12,24*ones(1,numel(this.ImCMaps)+numel(this.LabCMaps))]);
            else
                % needs to be removed
                for ii = 1:numel(this.DispToolArray)
                    set(this.DispToolArray{ii},'parent',[])
                end
                set(this.HideButton,'string',char(9650))
                set(this.MainVBox,'heights',[-1,12]);
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
                            set(this.PatchHandles{ch}(jj),'edgecolor',col)
                        end
                    
                        
                    end
            end
            
        end
        
        function imObj = getImObj(this)
            % seems trivial, but required for consistent interface
            imObj = this.AnObj.ImObj;
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
    end
end
