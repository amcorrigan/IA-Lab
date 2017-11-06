classdef DisplayManagerBase < handle %& matlab.mixin.SetGet % get rid of this!
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

    properties (Dependent)
        CurrentPanel % link to the TabPanel selection
        % for a grid panel, not sure the base class will cope with this,
        % might have to create a new GridPanel which keeps track of the
        % currently active window (changing the colour of the header, eg)

        CurrentDisplay
    end
    properties
        FigContainer % reference to the TabPanel or equivalent that holds the figpanels

        FigPanels = {};% cell array of uix.Panels (for now, could also be
                  % BoxPanels), each of which is a display
        CloseLstnrs = {}; % cell array of listeners for the display being closed from within
        DisplayObjects % cell array of display objects, so we can check what
                       % type of display is currently there
        NewTab = false; % open each image in the same panel by default

        Titles = {};

        NewImageLstnrs = {} % listener for a new image being generated from within and needing displaying
    end
    events
        addToWorkspace
        
        ImshowDone
    end
    methods
        function this = DisplayManagerBase(iParent,iFigContainer)

            if nargin<2 || isempty(iFigContainer)
                iFigContainer = uix.TabPanel('Padding',5);
            end
            if nargin<1 || isempty(iParent)
                iParent = gfigure();
            end


            tempVBox = uix.VBox('parent',iParent);
            % create the toolbar and then add the display container

            set(iFigContainer,'parent',tempVBox);
            this.FigContainer = iFigContainer;
            
            if isa(this.FigContainer,'uix.TabPanel')
                set(this.FigContainer,'SizeChangedFcn',@(src,evt)this.setTabWidths)
            end;

            aHandle = getFigParent(iParent);
            if ~isempty(aHandle)
                set(aHandle,'WindowScrollWheelFcn',@this.scrollfun)
            end
        end


        function refreshPanels(this,src,evt)
            % go through each display and refresh the image
            for jj = 1:numel(this.DisplayObjects)
              tempImObj = getImObj(this.DisplayObjects{jj});

              for ii = 1:numel(tempImObj.Channel)
                  this.DisplayObjects{jj}.colourCallback([],[],ii,[])
              end

                this.DisplayObjects{jj}.showImage();
            end
        end


        function snapshotcallback(this,src,evt)
            % first need to identify the current axes and copy them to an
            % invisible figure

            index = getCurrentIndex(this);
            if index==0
                return
                % no display to take a snapshot of
            end
            
% %             wb = SpinWheel('Saving Snapshot');
            progressBarAPI('init','Saving Snapshot');
            
            fig = gfigure('visible','off');

            % a better approach would be to let the DisplayObject determine
            % what is copied across - basically provide a graphics handle
            % containing the important parts
            
            this.DisplayObjects{index}.snapshotCopy(fig);
            
            % probably want a standard snapshot resolution, rather than
            % being dependent on the image size? Go for 1600 width
            
            savename = sprintf('Snapshot%s',datestr(now,'dd-mm-yy_HHMM-SS'));
            
            set(fig,'inverthardcopy','off')
            print(fig,'-dtiff','-r100',savename)

            close(fig)
% %             delete(wb)
            progressBarAPI('finish');
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

                this.Titles(ind(ii)) = [];

              %  this.ScrollFunctions(ind(ii)) = [];

            end
            
            if isa(this.FigContainer,'uix.BoxPanel')
                set(this.FigContainer,'Titles',this.Titles);
                this.setTabWidths();
            elseif isa(this.FigContainer, 'uix.BoxPanel')
                set(this.FigContainer,'Title',this.Titles);
            elseif isa(this.FigContainer,'uix.TabPanel')
                set(this.FigContainer,'TabTitles',this.Titles);
                this.setTabWidths();
            end
            
            fixPanelGeometry(this);
        end

        function fixPanelGeometry(this)
            if isa(this.FigContainer,'uix.Grid')
                gsiz = ceil(sqrt(numel(this.FigPanels)));
                if gsiz>0
                    set(this.FigContainer,'Heights',-ones(1,gsiz),'Widths',-ones(1,gsiz))
                end
            end
        end
        function setTabWidths(this)
            % recalculate the tab widths based on how many tabs are
            % open and how wide the panel is
            
            if isa(this.FigContainer,'uix.TabPanel')
                pos = get(this.FigContainer,'position');
                % positions should already be in pixels

                newwid = min(160,max(10,ceil(pos(3)/numel(this.FigPanels) - 11)));

                set(this.FigContainer,'TabWidth',newwid)
            end
       end


        function scrollfun(this,src,evt)
            % pass on the scrolling to the appropriate display method
            % don't need to actually store the scroll functions in this class.
            if isa(this.FigContainer,'uix.TabPanel')
                index = this.FigContainer.Selection;
                this.DisplayObjects{index}.scrollfun(src,evt);
            else
                for ii = 1:numel(this.DisplayObjects)
                    this.DisplayObjects{ii}.scrollfun(src,evt);
                end
            end
        end

        %-- Not required by RGB image, but would need for tabed images.
        function [panelh,index] = getCurrentPanel(this)
            % if it's a tabpanel, get the panel which is the current
            % selection
            % otherwise, don't do anything yet

            index = this.getCurrentIndex();

            if index==0
                % need to create a new panel
                index = 1;
                panelh = this.createNewPanel();
            else
                panelh = this.FigPanels{index};
            end

        end
        
        function oDispObj = getCurrentDisplay(this)
            % get the current display object, but don't create anything if
            % it doesn't exist - return empty vector in this case
            index = getCurrentIndex(this);

            if index==0 || index>numel(this.DisplayObjects)
                oDispObj = [];
            else
                oDispObj = this.DisplayObjects{index};
            end

        end

        %-- Not required by RGB image, but would need for tabed images.
        function index = getCurrentIndex(this)
            if isa(this.FigContainer,'uix.TabPanel')
                index = this.FigContainer.Selection;
            else
                index = numel(this.FigPanels);
            end

            
% %             index = numel(this.FigPanels);
        end

        function varargout = sendToDisplay(this,imObj)
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
                dispObj = imObj.defaultDisplayObject(panelh);

                dispObj.showImage(imObj);
                
                stage = 1;
                
                this.DisplayObjects{index} = dispObj;
                
                stage = 2;
                this.Titles{index} = imObj.Tag;
                if isa(this.FigContainer,'uix.BoxPanel')
                    set(this.FigContainer,'Title', this.Titles);
                    
                    aColour = 1- rand(1, 3) * 0.5;
                    set(this.FigContainer, 'TitleColor', aColour);
                elseif isa(this.FigContainer,'uix.TabPanel')
                    set(this.FigContainer,'TabTitles',this.Titles);
                end

                
                stage = 3;
                this.CloseLstnrs{index} = addlistener(dispObj,'closeRequest',@this.deletePanel);

                notify(this,'ImshowDone');
                
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

        function varargout = createNewPanel(this)
            % create a new panel, set it to the current panel if
            % appropriate, and then return the handle
            index = numel(this.FigPanels) + 1;

            % for positioning of multiple axes, the standard uipanel seems
            % to work fine
            % perhaps we need to decide on a standard for image display
            % I've used uipanel here to allow complete freedom of what goes
            % inside (ie without layout managing), while still being
            % accepting uix stuff like HBoxes and GridLayouts
            % The difference is that, if the uix becomes the standard
            % method for setting up displays, the uipanel just adds an
            % extra, unnecessary layer.

%             this.FigPanels{index} = uix.Panel('parent',this.FigContainer);
            this.FigPanels{index} = uipanel('parent',this.FigContainer);
            if isa(this.FigContainer,'uix.TabPanel')
                this.FigContainer.Selection = index;
            end
            this.Titles{index} = sprintf('Page %d',index);
            fixPanelGeometry(this);

            %-- TODO: Yinhai
            if isa(this.FigContainer,'uix.TabPanel')
               this.setTabWidths();
            end;
            
            if nargout>0
                varargout{1} = this.FigPanels{index};
            end

        end
    end

    methods (Static)
        function clearPanel(panelh)
            % clear the contents of the panel in the input
            % this is a static method because it doesn't require the
            % DisplayManager instance to run it, but it seems to make
            % sense to keep this function with the class

            ch = get(panelh,'children');
            for ii = 1:numel(ch)
                delete(ch(ii));
            end % for loop probably not required, but this makes the order of deletion explicit
        end
    end

end
