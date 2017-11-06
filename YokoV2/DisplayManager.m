classdef DisplayManager < DisplayManagerBase
    % This is the part of the explorer responsible for collecting together
    % the displays
    % Previously it was called FigureTabs

    % TO DO:
    % - contrast adjustment has changed slightly, make sure it is consistent with
    %   the standalone AZDisplayFig and works reliably.
    % - might want to be able to paste the current tab's colour settings to every
    %   panel, to make them look the same.

    % Rather than simply BEING a TabPanel, have it referencing the
    % container, as well as the individual panels, so that the style can be
    % changed easily

    % we might also want to keep track of what type of display is in each
    % panel currently, to decide if it necessary to wipe it.

% %     properties (Dependent)
% %         CurrentPanel % link to the TabPanel selection
% %         % for a grid panel, not sure the base class will cope with this,
% %         % might have to create a new GridPanel which keeps track of the
% %         % currently active window (changing the colour of the header, eg)
% % 
% %         CurrentDisplay
% %     end
    properties

        FigTool
        ZoomButton
        PanButton
        ContrastButton
        AutoContrastButton
        ResetContrastButton
        AddBox % hbox for adding optional buttons to the toolbar
        
        SnapshotButton
        Delete1Button
        DeleteAllButton
        
        ChannelLabels

% %         FigContainer % reference to the TabPanel or equivalent that holds the figpanels
% % 
% %         FigPanels = {};% cell array of uix.Panels (for now, could also be
% %                   % BoxPanels), each of which is a display
% %         CloseLstnrs = {}; % cell array of listeners for the display being closed from within
% %         DisplayObjects % cell array of display objects, so we can check what
% %                        % type of display is currently there
% %         %ScrollFunctions = {}; % array of function handles for the scroll wheel functions
% %                               % call the currently selected one for tabs, call all of them
% %                               % for the grid display
        ImageTemplateObjects % cell array of empty 3DnC objects, ready to be passed to the image bank
% %         NewTab = true; % open each image in a new tab by default
% % 
% %         Layout = 'tabs';
% %         Titles = {};

        FigDisplayMenu; % uimenu handle for the main entry
        NewTabMenu; %uimenu entry to toggle new tab creation
        ContainMenu;

% %         StyleMenu; % default display style could also be set using a settings dialog

        ContrastObj; % object responsible for contrast adjustment
        ContrastLstnr; % listener for changes in contrast
        AutoContrastLstnr % listener for clicking the autocontrast button
% %         NewImageLstnrs = {} % listener for a new image being generated from within and needing displaying
    end
% %     events
% %         addToWorkspace
% %     end
    methods
        function this = DisplayManager(iParent,iFigContainer)
            
            
            if nargin<2 || isempty(iFigContainer)
                iFigContainer = uix.TabPanel('Padding',5);
            end
            if nargin<1 || isempty(iParent)
                iParent = gfigure();
            end

            
            this = this@DisplayManagerBase(iParent,iFigContainer);
            
            this.NewTab = true;
            
            this.createToolbar();
            this.addContrastToolbar();
            
            % also add the menu to the figure
            % farm this out to a new method
            this.setupMenuEntry();

        end
        
        function createToolbar(this)
            tempVBox = get(this.FigContainer,'parent');
            
            this.FigTool = uix.HBox('parent',tempVBox);

            
%             uix.Empty('parent',this.FigTool); % spacer

            this.AddBox = uix.HBox('parent',this.FigTool);
%             this.SnapshotButton = uicontrol('parent',this.AddBox,'style','pushbutton',...
%                 'cdata',imresize(imread('yokosnapshot.png'),0.8),'callback',@this.snapshotcallback);
           
            uix.Empty('parent',this.AddBox); % spacer
            numButtons = 0;
            
            % add left and right buttons to move the currently selected
            % panel
            templeft = uicontrol('parent',this.FigTool,'Style','pushbutton',...
                'String','<','callback',{@this.movePanel,'left'});
            numButtons = numButtons + 1;
            tempright = uicontrol('parent',this.FigTool,'Style','pushbutton',...
                'String','>','callback',{@this.movePanel,'right'});
            numButtons = numButtons + 1;
            
            this.Delete1Button = uicontrol('parent',this.FigTool,'Style','pushbutton','callback',...
                @this.deletePanel,'cdata',imresize(imread('yokodelete.png'),[20 20]));
            numButtons = numButtons + 1;
            this.DeleteAllButton = uicontrol('parent',this.FigTool,'Style','pushbutton','callback',...
                {@this.deletePanel,'all'},'cdata',imresize(imread('yokodeleteAll.png'),[20 20]));
            numButtons = numButtons + 1;
            
            set(this.FigTool,'Widths',[-1,24*ones(1,numButtons)],'spacing',4)
            set(this.AddBox,'Widths',-1,'spacing',4);
            
            
% %             set(iFigContainer,'parent',tempVBox);
            ch = get(tempVBox,'children');
            set(tempVBox,'Children',ch(end:-1:1))
            set(tempVBox,'Heights',[24,-1])

        end
        
        function addContrastToolbar(this)
            
            % take the empty placeholder out, and then put it back once the
            % new buttons have been put in place
            % could also be done by rearranging the children if that is
            % more satisfactory, see the commented out code below
            temp = get(this.AddBox,'children');
            temp = temp(1); % should never be empty
            set(temp,'parent',[])
            
            this.ContrastButton = uicontrol('parent',this.AddBox,'style','pushbutton',...
                'String','Contrast','callback',@this.contrastcallback);
            this.AutoContrastButton = uicontrol('parent',this.AddBox,'style','pushbutton',...
                'String','Auto','callback',@this.autocontrastcallback);
            this.ResetContrastButton = uicontrol('parent',this.AddBox,'style','pushbutton',...
                'String','Reset','callback',@this.resetContrast);
%             
%             ch = get(this.AddBox,'children');
%             ch = ch([end,1:end-1]);
            
            set(temp,'parent',this.AddBox)
            set(this.AddBox,'widths',[50,50,50,-1])
            
            
        end
        
        
        % this will get called by the main class when there is an image
        % loader added.
        function setupContrast(this,chanlabels)
            % need to know how many channels there are?
            
            this.ChannelLabels = chanlabels;
            
            if ishandle(this.ContrastObj)
                delete(this.ContrastObj);
            end;

            this.ContrastObj = ContrastAdjust16bit(this.ChannelLabels);
            
            % don't require any display until the user clicks the contrast
            % button
            this.ContrastLstnr = addlistener(this.ContrastObj,'settingsUpdate',@this.refreshPanels);
            this.AutoContrastLstnr = addlistener(this.ContrastObj,'autoRequest',@this.autoContrast);
        end

        function autoContrast(this,src,evt)
            index = getCurrentIndex(this);
            ch = evt.data;

            % this requires some more work to figure out which channel
            % belongs to which figure
            tempImObj = this.DisplayObjects{index}.ImObj;
            chanind = ch==tempImObj.Channel;
            if nnz(chanind)==1
                % see if we can get the limits from the image data
                rawdata = tempImObj.rawdata();
                if iscell(rawdata)
                    rawdata = rawdata{chanind};
                end

                imlimits = [min(rawdata(:)),max(rawdata(:))];

                infoupdate(this.ContrastObj,imlimits,ch)
            end

        end

        function autocontrastcallback(this,src,evt)
            % want to automatically set the contrast based on the
            % histograms of the current image, if possible

% %             wb = SpinWheel('Calculating auto contrast');
            progressBarAPI('init','Calculating auto contrast');

            index = getCurrentIndex(this);

            tempImObj = this.DisplayObjects{index}.ImObj;

            % see if we can get the limits from the image data
            rawdata = tempImObj.rawdata();
            if ~iscell(rawdata)
                rawdata = {rawdata};
            end

            % try some basic equalization
            % if we want the image to be approximately exponentially
            % distributed, then?
            for ii = 1:numel(rawdata)
                % need to know what channel this corresponds to
                ch = tempImObj.Channel(ii);
                if ch>0 && ch<=this.ContrastObj.numCh
    %                 tempyy = (0:0.2:1)';
                    tempyy = [0;0.7;1];
                    hval = max(rawdata{ii}(:));
                    lval = min(rawdata{ii}(:));

                    nn = cumsum(imhist(rawdata{ii}(:),65536));
                    nn = nn/nn(end);
                    tempidx = find(nn<0.7,1,'last');
                    if isempty(tempidx)
                        tempidx = 0.7;
                    end
                    tempxx = [0;tempidx/65536;1];

                    tempxx = 0.5*tempyy + 0.5*tempxx;
                    try
                    this.ContrastObj.lowval(ch) = lval;
                    this.ContrastObj.hival(ch) = hval;

                    this.ContrastObj.xx{ch} = tempxx;
                    this.ContrastObj.yy{ch} = tempyy;
                    catch ME
                        rethrow(ME)
                    end
                end
            end


  %          % just call the method directly
            try
            updateProcArray(this.ContrastObj)
            catch ME
                rethrow(ME)
            end
            refreshPanels(this);

% %             delete(wb);
            progressBarAPI('finish');
        end
        
        function resetContrast(this,src,evt)
            this.ContrastObj.reset();
            refreshPanels(this);
        end

        function contrastcallback(this,src,evt)
            % bring up the window of contrast adjustment

            this.ContrastObj.showGUI

        end

        function deletePanel(this,src,evt,ind)
            if nargin<4 || isempty(ind)
                % see if the source is one of the display panels
                if isa(src,'cDisplayInterface')
                    % check the event data for one or all panels closed
                    if ischar(evt.data) && strcmpi(evt.data,'all')
                        ind = 'all';
                    else
                        ind = find(cellfun(@(x)isequal(x,src),this.DisplayObjects));
                    end
                else
                    ind = getCurrentIndex(this);
                end
            end
            if ischar(ind) && strcmpi(ind,'all')
                ind = 1:numel(this.FigPanels);
            end
            if isempty(ind)
                return
            end
            
            ind(ind>numel(this.FigPanels)) = [];
            
            % need to work out the order of deletion that doesn't mess with
            % the order of the other indices
            for ii = numel(ind):-1:1
                this.clearPanel(this.FigPanels{ind(ii)});
                this.DisplayObjects(ind(ii)) = [];

                % remove the panel from FigContainer
                delete(this.FigPanels{ind(ii)});
                this.FigPanels(ind(ii)) = [];
                this.CloseLstnrs(ind(ii)) = [];
                this.NewImageLstnrs(ind(ii)) = [];
                this.Titles(ind(ii)) = [];

              %  this.ScrollFunctions(ind(ii)) = [];

                % remove the image template from the list
                this.ImageTemplateObjects(ind(ii)) = [];
            end
            if isa(this.FigContainer,'uix.TabPanel')
                set(this.FigContainer,'TabTitles',this.Titles)
            end

            fixPanelGeometry(this);
            this.setTabWidths();
        end

        function fixPanelGeometry(this)
            if isa(this.FigContainer,'uix.Grid')
                gsiz = ceil(sqrt(numel(this.FigPanels)));
                if gsiz>0
                    set(this.FigContainer,'Heights',-ones(1,gsiz),'Widths',-ones(1,gsiz))
                end
            end
        end

        function setupMenuEntry(this)
            % find the parent figure
            fig = getFigParent(this.FigContainer);
            if isempty(fig)
                error('can''t find parent figure! This shouldn''t happen')
            end

            this.FigDisplayMenu = uimenu(fig,'Label','Display');

            if this.NewTab
                checkstr = 'on';
            else
                checkstr = 'off';
            end
            this.NewTabMenu = uimenu(this.FigDisplayMenu,'Label','Open in new tab',...
                'Checked',checkstr,'callback',@this.toggleNewTab);

            this.ContainMenu = uimenu(this.FigDisplayMenu,'Label','Switch to grid',...
                'callback',@this.switchLayout);

            % Display preferences here can override the default image
            % settings
% %             this.StyleMenu = uimenu(this.FigDisplayMenu,'Label','Preferences...',...
% %                 'callback',@this.prefChoiceGUI);

        end

        function scrollfun(this,src,evt)
            % pass on the scrolling to the appropriate display method
            % don't need to actually store the scroll functions in this class.
            if isa(this.FigContainer,'uix.TabPanel')
                index = this.FigContainer.Selection;
                if isempty(index) || index==0
                    return
                end
                this.DisplayObjects{index}.scrollfun(src,evt);
            else
                for ii = 1:numel(this.DisplayObjects)
                    this.DisplayObjects{ii}.scrollfun(src,evt);
                end
            end
        end

        function switchLayout(this,src,evt)
            % the best way of switching between tabs and grid depends
            % partly on how the uix toolbox does things

            if isa(this.FigContainer,'uix.TabPanel')
                % switch to grid
                set(this.ContainMenu,'Label','Switch to tabs')

                tempContainer = uix.Grid;

                for ii = 1:numel(this.FigPanels)
                    set(this.FigPanels{ii},'visible','on','parent',tempContainer)
                end

                % set the widths and height to be as square as possible
                gsiz = ceil(sqrt(numel(this.FigPanels)));
                set(tempContainer,'widths',-ones(1,gsiz),'heights',-ones(1,gsiz));

                % then delete the existing tab panels and replace it with
                % the grid
                set(this.FigContainer,'parent',[])
                delete(this.FigContainer)
                this.FigContainer = tempContainer;
                set(this.FigContainer,'Parent',get(this.FigTool,'parent'))
            elseif isa(this.FigContainer,'uix.Grid')
                % switch to tabs

                set(this.ContainMenu,'Label','Switch to grid')

                tempContainer = uix.TabPanel;

                for ii = 1:numel(this.FigPanels)
                    set(this.FigPanels{ii},'parent',tempContainer)
                end


                % then delete the existing container and replace it with
                % the grid
                set(this.FigContainer,'parent',[])
                delete(this.FigContainer)
                this.FigContainer = tempContainer;
                set(this.FigContainer,'Parent',get(this.FigTool,'parent'))
                
                set(this.FigContainer,'TabTitles',this.Titles)
                set(this.FigContainer,'SizeChangedFcn',@(src,evt)this.setTabWidths)
                
                this.setTabWidths();
% %             else
% %                 % don't do anything if neither tabs nor grid
            end
        end

        function prefChoiceGUI(this,src,evt)
            IAHelp(src,evt)

        end
        
        

        function o3DnCObj = getCurrentTemplate(this)
            index = getCurrentIndex(this);

            if index==0 || index>numel(this.DisplayObjects)
                o3DnCObj = [];
            else
                o3DnCObj = this.ImageTemplateObjects{index};
            end

        end


        function varargout = sendToDisplay(this,imObj,file3DnCObj)
            % as well as the actual image, we also want to store the empty
            % 3DnC object in case we add it to the segmentation list


            if this.NewTab % want this to be setget really, so that the menu also gets updated
                % if NewTab is set get, no need to store it as concrete
                % property
                % basically create a new panel to pass to the DisplayObject
                this.createNewPanel();

            end
            
            % get the current panel
            [panelh,index] = this.getCurrentPanel;
            stage = 0;
            try
                % see if there is a display object associated with it
                dispObj = this.getCurrentDisplay;
                % also need to know the index so that it can be added to the
                % DisplayObjects list
                % maybe these two can be merged into a single method?

                % if no display object (empty), create one
                % otherwise get relevant info from the panel, clear it and then
                % create the new one

                if ~isempty(dispObj)
                    dispInfo = dispObj.getInfo;
                    DisplayManager.clearPanel(panelh); % static method, see below
                else
                    dispInfo = [];
                end

                % no user preferences yet 
                
                % keep track of the stage so we know what to clean up in
                % the event of an error
                
                if isempty(imObj)
                    error('IA:Empty','No image selected')
                end
                dispObj = imObj.defaultDisplayObject(panelh,this.ContrastObj,dispInfo);
                
                
                % pass the channel information to the display object
                % a better (but much more complex) solution would give the
                % image object labels for each channel - this could be done
                % for the next version
                dispObj.addChannelLabels(this.ChannelLabels);

                dispObj.showImage(imObj);
                
                stage = 1;
                
                this.DisplayObjects{index} = dispObj;
                
                stage = 2;
                this.Titles{index} = imObj.Tag;
                if isa(this.FigContainer,'uix.TabPanel')
                    set(this.FigContainer,'TabTitles',this.Titles);
                end

                if nargin>2 && ~isempty(file3DnCObj)
                    this.ImageTemplateObjects{index} = file3DnCObj;
                else
                    this.ImageTemplateObjects{index} = [];
                end
                stage = 3;
                this.CloseLstnrs{index} = addlistener(dispObj,'closeRequest',@this.deletePanel);
                this.NewImageLstnrs{index} = addlistener(dispObj,'imageEvent',@this.imageEventCallback);
                
            catch ME % can use the error message to decide what to do at some point
                
                delete(this.FigPanels{index});
                this.FigPanels(index) = [];
                
                % tidy up to get back to where we were at the start
%                 this.clearPanel(this.FigPanels{index});
                if stage>0
                    this.DisplayObjects(index) = [];
                end
                if stage>1
                    this.Titles(index) = [];
                    this.ImageTemplateObjects(index) = [];
                end
                if stage>2

                    this.CloseLstnrs(index) = [];
                    this.NewImageLstnrs(index) = [];

                    
                end
                
                % show a message reporting the error
                if strcmpi(ME.identifier,'IA:Cancel')
                    h = msgbox('Cancelled by user','Cancelled');
                    set(h,'WindowStyle','modal')
                    uiwait(h);
                elseif strcmpi(ME.identifier,'IA:Empty')
                    h = msgbox('No image has been found','No image');
                    set(h,'WindowStyle','modal')
                    uiwait(h);
                else
                    h = msgbox(sprintf('Details: method %s, line %d',...
                        ME.stack(1).name,ME.stack(1).line),'Error occurred');
                    set(h,'WindowStyle','modal')
                    uiwait(h);
                end
            end
            
            if nargout>0
                varargout{1} = dispObj;
            end
        end


        function toggleNewTab(this,src,evt)
            if strcmpi(get(this.NewTabMenu,'Checked'),'On')
                set(this.NewTabMenu,'Checked','Off')
                this.NewTab = false;
            else
                set(this.NewTabMenu,'Checked','On')
                this.NewTab = true;
            end
        end
        
        function imageEventCallback(this,src,evt)
            % a new image has been sent from one of the displays, to be
            % shown as a new image
            % This is likely to be a maximum projection or similar
            
            if ~this.NewTab
                % ensure that a new panel is created if it wouldn't be
                % otherwise
                this.createNewPanel();
            end
            this.sendToDisplay(evt.data);
            
        end
        
        function movePanel(this,src,evt,direction)
            
            numPanels = numel(this.DisplayObjects);
            
            if numPanels==1
                % nothing to do..
                return
            end
            
            % Properties that need to be changed
            % - FigPanels
            % - Titles
            % - ImageTemplateObjects (if not empty)
            % - DisplayObjects
            % - CloseLstnrs
            % - NewImageLstnrs
            % - the children of FigContainer - think this is in the wrong
            %   order
            
            index = getCurrentIndex(this);
            neworder = 1:numPanels;
            childorder = 1:numPanels;
            childindex = numPanels + 1 - index;
                    
            switch direction
                case 'left'
                    if index==1
                        return
                    end
                    % need to rearrange the display objects, the template
                    % stored objects and the boxpanel children
                    neworder([index-1,index]) = [index,index-1];
                    childorder([childindex,childindex+1]) = [childindex+1,childindex];
                    newindex = index - 1;
                    
                otherwise
                    if index==numPanels
                        return
                    end
                    % need to rearrange the display objects, the template
                    % stored objects and the boxpanel children
                    neworder([index,index+1]) = [index+1,index];
                    childorder([childindex-1,childindex]) = [childindex,childindex-1];
                    newindex = index + 1;
                    
            end
            this.FigPanels = this.FigPanels(neworder);
            this.Titles = this.Titles(neworder);
            this.ImageTemplateObjects = this.ImageTemplateObjects(neworder);
            this.DisplayObjects = this.DisplayObjects(neworder);
            this.CloseLstnrs = this.CloseLstnrs(neworder);
            this.NewImageLstnrs = this.NewImageLstnrs(neworder);
            this.FigContainer.Children = this.FigContainer.Children(childorder);
            set(this.FigContainer,'TabTitles',this.Titles)
            set(this.FigContainer,'Selection',newindex)
        end
    end

end
