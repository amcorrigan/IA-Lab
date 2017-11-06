classdef YEMain < handle
    properties (SetAccess = protected)
        Figure1
        FigureMaster
        FigureLeft
        FigureRight
        
        FigureTabs % instance of class DisplayManager, which handles the display of multiple images

        LoaderObj
        FigureChoices % will replace the Plate and Explore portions of YE

        AutoLoad = true; % will be used to toggle whether the image is automatically displayed
                         % or only when the user says so.
        % uimenu handles
        FileMenu
        LoadMenu
        CloseMenu
        
        HelpMenu

        HelpIcon
        
        Toolbar
    end

    properties % listeners
        ChoiceLstn % listens for when a new image is requested
    end %--listeners
    methods
        function this = YEMain(imgLoader, aName)
            
            if nargin <= 1
                aName = 'IALab';
            end;
            
            % if a preexisting figure can be passed as an input, then this
            % can be run modally. runModal can already be used as a stopgap

            initialize(this, [], aName);
            if nargin>0 && ~isempty(imgLoader)
                setLoader(this,imgLoader);
            end
        end
        
        function initialize(this,fig, aName)
            if nargin <= 2
                aName = 'IALab';
            end;
            
            if nargin<2 || isempty(fig)
                fig = gfigure('Name', aName);
            end
            
            progressBarAPI('finish'); % flush any preexisting progress bars
            
            this.HelpIcon = imread('yokoYWang.png');
            this.Figure1 = fig;
            
            this.Toolbar = uitoolbar('parent',this.Figure1);
            this.setToolbarItems();
            

            this.FigureMaster = uix.HBoxFlex( 'Parent', this.Figure1, 'Spacing', 10, 'Padding', 5, 'BackgroundColor', [1 1 1]);

            this.FigureLeft = uix.VBoxFlex( 'Parent', this.FigureMaster, 'Spacing', 10, 'BackgroundColor', [1 1 1]);
            this.FigureRight = uix.VBox( 'Parent', this.FigureMaster, 'Spacing', 10, 'BackgroundColor', [0 0 0] );

            set( this.FigureMaster, 'Widths', [-1 -3]);

            this.setupMenuEntry();
           
            this.setDisplayManager();            
            
            % rearrange the menus so that the help goes at the end
            set(this.HelpMenu,'parent',[])
            set(this.HelpMenu,'parent',this.Figure1);
        end
        
        function setDisplayManager(this)
                    
            % want FigureTabs to be both the display tabs/grid and the
            % toolbar that goes with it
            this.FigureTabs = DisplayManager(this.FigureRight,uix.TabPanel('Padding', 5));
        end
        
        
        function setupMenuEntry(this)

            this.FileMenu = uimenu(this.Figure1,'Label','Load');
            this.LoadMenu = uimenu(this.FileMenu,'Label','New...',...
                'callback',@this.setupLoader);
            this.CloseMenu = uimenu(this.FileMenu,'Label','Close',...
                'callback',@this.closeLoader);
            
            
            this.HelpMenu = uimenu(this.Figure1,'Label','Help');
            uimenu(this.HelpMenu,'Label','About..',...
                   'callback',@this.aboutcallback);
            uimenu(this.HelpMenu,'Label','Wishlist',...
                   'callback',@this.wishlistCallback);
            
        end

        function setToolbarItems(this)
            %______________________________________________________________
            % 1. Load Experiment
            icon = imread('file_open.png');
            icon = im2double(icon);       
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','Load Experiment(s)',...
                       'ClickedCallback', @this.setupLoader,...
                       'CData', icon);
                   
            %______________________________________________________________
            % 2. Screenshot
            icon = imread('yokoScreenshot.png');
            icon = im2double(icon);       
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','Take a Snapshot',...
                       'ClickedCallback', @this.snapshotCallback,...
                       'Separator','on',...
                       'CData', icon);
                   
            %______________________________________________________________
            % 3. Platemap (uses explorer icon)
            icon = imread('yokoExplore.jpg');
            icon = im2double(icon);       
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','Show Plate Map',...
                       'ClickedCallback', @this.thumbnailCallback,...
                       'CData', icon);
                   
                   
            %______________________________________________________________
            % 4. About
            icon = imresize(imread('yokoAbout.png'), [16 16]);
            icon = im2double(icon);
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','About',...
                       'ClickedCallback', @this.aboutcallback,...
                       'Separator','on',...
                       'CData', icon);
                   
            %______________________________________________________________
            % 5. Wishlist
            icon = imresize(imread('yokoWishlist.jpg'), [16 16]);
            icon = im2double(icon);       
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','Wishlist',...
                       'ClickedCallback', @this.wishlistCallback,...
                       'CData', icon);
        end
        
        % --------------------------------------------------------------------
        %-- Mainly used for HCB gives us feedbacks
        function wishlistCallback(this, hObject, eventdata)
            winopen('\\UK-Image-01\IAGroup\SB\2016\Yoko\Source Code\WishList.xlsx');
        end
      
        %-- setup snapshot icon on Toolbar
        function snapshotCallback(this,src,evt)
            this.FigureTabs.snapshotcallback(src,evt);
        end

        %-- setup thumbnail icon on Toolbar
        function thumbnailCallback(this,src,evt)
            aFile = fullfile(this.LoaderObj.PlatePath, '__thumb.mat');
            
            flag = exist(aFile, 'file');
            if flag == 0
                thumbObj = this.LoaderObj.setThumbnail();
                
                if isempty(thumbObj)
                    return
                end
                save(fullfile(this.LoaderObj.PlatePath, '__thumb.mat'), 'thumbObj');
            else
                load(aFile, 'thumbObj');
            end
            
            %%--- to send to a cImage object for display
            this.FigureTabs.sendToDisplay(thumbObj);
        end        
        
        function setupLoader(this,src,evt,imgLoader)
            % This method will be used separately from setLoader below to
            % guide the user to choose the appropriate type of loader for
            % their experiment

            if nargin<4 || isempty(imgLoader)
                % prompt the user to select a folder (or XML file?) from which to
                % create a ParserYokogawa object
                % in time, this part will be able to choose or detect what type
                % of imgLoader has been selected by the user, but for now the CV7000
                % is the only one required
                imgLoader = ParserYokogawa.browseForFile();
            end

            if isempty(imgLoader)
                % do nothing
                % will want to display a message at some point

                return
            end

            % now that we have an imgLoader object, use that to provide the ChoicePanel object
            % to populate the FigureLeft region.

% %             wh = SpinWheel('Setting up..');
            progressBarAPI('init','Setting up..');
            setLoader(this,imgLoader);
% %             delete(wh);
            progressBarAPI('finish');
        end

        function setLoader(this,imgLoader)
            if nargin>1 && isValidLoader(this,imgLoader)
                
                this.LoaderObj = imgLoader;
            end

            if isempty(this.LoaderObj)
                return
            end

            if ~isempty(this.FigureChoices)
                % deletefcn needs to take care of removing the panels and
                % setting up again
                delete(this.FigureChoices)
                
                % the image bank will also need deleting if it already exists
% %                 delete(this.ImageBankObj)
            end
            
            % Generate the style of GUI from a method of the loader object
            this.FigureChoices = this.LoaderObj.getChoiceGUI(this.FigureLeft);
            %-- TODO
%             set(this.LeftPanel,'TabTitles',[get(this.LeftPanel,'TabTitles'),{'Browser'}])
            
            aString = sprintf('IALab - %s', this.LoaderObj.getTitle());
            set(this.Figure1, 'name', aString);
            
% %             this.ImageBankObj = ImageBank(this.FigureLeft);
            % add the bank button to the DisplayManager from here
% %             if isempty(this.BankButton)
% %                 this.BankButton = uicontrol('parent',this.FigureTabs.AddBox,'style','pushbutton',...
% %                     'String','Add to Bank','callback',@this.bankcallback);
% %                 temp = get(this.FigureTabs.AddBox,'children');
% %                 tempwids = get(this.FigureTabs.AddBox,'widths');
% %                 
% %                 set(this.FigureTabs.AddBox,'children',temp([2,1,3:end]));
% %                 
% %                 tempwids(end-1:end) = [100,-1];
% %                 set(this.FigureTabs.AddBox,'widths',tempwids)
% %             end

            
%             this.BankLstn = addlistener(this.FigureTabs,'addToBank',@this.sendToBank);
% %             this.DisplayFromBankLstn = addlistener(this.ImageBankObj,'displayFromBank',@this.dispFromBank);

% %             set(this.FigureLeft,'heights',[-5,-1]);
            
            resetContrast(this)

            % initialize ( might not want to do this by default)
%             this.getNewImage();
        end
        
        function closeLoader(this,src,evt)
            if ~isempty(this.FigureChoices)
                % deletefcn needs to take care of removing the panels and
                % setting up again
                delete(this.FigureChoices)

                % the image bank will also need deleting if it already exists
% %                 delete(this.ImageBankObj)
            end
            
            set(this.Figure1, 'name', 'IALab');            
        end
        
        %-- TODO: may need to move to HCExplorer or better wrapped up
        function resetContrast(this)
            
            % use max rather than numel to keep the actual channel number
            % lined up
            
%             this.TotalNumChan = max(getChoices(this.LoaderObj.IC,'channel'));
            % This needs to change because the Loader no longer contains IC
            % should be a method from the loader
% %             this.TotalNumChan = getTotalNumChan(this.LoaderObj);
% %             this.FigureTabs.setupContrast(this.TotalNumChan);
            
            this.FigureTabs.setupContrast(this.LoaderObj.ChannelLabels);
            
            
% % %             addNumChan(this.SegManagerObj,this.TotalNumChan);

            % listen for clicks on the GUI
            %%IMPORTANT - think this should be in the setLoader method
            %%instead
            this.ChoiceLstn = addlistener(this.FigureChoices,'choiceUpdate',@this.getNewImage);

        end
        
        function val = isValidLoader(this,imgLoader)
            % add more to this as we go along
            % A better option would be to make sure that all completed
            % image loaders inherit from a common base class that can be
            % checked for here.
% %             val = isa(imgLoader,'ParserHCB');
            val = isa(imgLoader,'ImgLoader');
        end

        function getNewImage(this,src,evt)
            if nargin>1 && isequal(src,this.FigureChoices)
                % comes from the selection triggered event, check for auto
                % load
                if ~this.AutoLoad
                    return
                end
            end

% %             wh = SpinWheel('Loading image..');
            progressBarAPI('init','Loading image..')
            % otherwise, want to get the appropriate image depending on the
            % current display mode, stored in this.FigureChoices.blendMode

            % rather than have this class work out what image should be
            % loaded, have that as a method of the image loader, which also
            % takes the current display mode from FigureChoices as an
            % input
            % I THINK THE NAME OF THIS SHOULD BE CHANGED TO LOAD SELECTED
            % IMAGE, AND TAKE THE WHOLE FIGURECHOICES RATHER THAN JUST THE
            % BLEND MODE
% %             imObj = loadCurrentImage(this.LoaderObj,this.FigureChoices.blendMode);

            imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);

            % as well as the actual image for display, in the background we
            % also want to store the relevant empty 3DnC object so that it
            % can be added to the set of current images for segmentation
            
% %             emptyObj = this.LoaderObj.getCurrentEmptyImage(this.FigureChoices);
            
            % the objects are now cell arrays in preparation for passing
            % multiple images at a time
            
            for ii = 1:numel(imObj)
                this.FigureTabs.sendToDisplay(imObj{ii});
%                 this.FigureTabs.sendToDisplay(imObj{ii},emptyObj{ii});
                
                % at some point will want to toggle the open new tabs part
                % here for ii>1
            end
            
            progressBarAPI('finish')

%             delete(wh);
%             keyboard
        end
        
        function aboutcallback(this,src,evt)
            YEAbout();
        end
        
        %-- a placeholder for functions not implemented by IA team
        function missingFunctionality(this,src,evt)
            % display a message window to show the functionality isn't yet
            % implemented
            h = msgbox('This functionality hasn''t yet been added','Work in progress',...
                'custom',this.HelpIcon);
            set(h,'WindowStyle','modal')
            uiwait(h);
        end
    end
end
