classdef HCExplorer < YEMain
    % The next implementation of YEMain, including support for multiple
    % parsers, and the ability to launch analysis.
    properties
        LoadOptions
        
        LeftPanel
        
        WSObj
        WSButton
        WSLstn
        DirectBankLstn
        
        FlowObj
        SegGUIObj
        
        AnalysisMenu
        CalibrationMenu
        
        QCLoadButton
%         QCDisplayStyle = 'seg'
        IndividualQCMenu;
        
        ProjectLoadMenu
        ProjectSaveMenu
    end
    
    properties
        DisplayFromWSLstn % listen for an image from the bank being sent to the display
    end
    
    methods
        function this = HCExplorer(imgLoader)
            
            % call without any parser, to make sure that we can set up the
            % tab panel first
            this = this@YEMain();
            
            set(this.Figure1,'Name','IA Explorer')
            
            % put the parser into a tabpanel, so that segmentation can be
            % added
            this.LeftPanel = uix.TabPanel('parent', this.FigureLeft,'tabwidth',100);
            
            if nargin>0 && ~isempty(imgLoader)
                this.setLoader(imgLoader);
            end
        end
        
        function setupMenuEntry(this)
            this.FileMenu = uimenu(this.Figure1,'Label','Experiment');
            this.LoadMenu = uimenu(this.FileMenu,'Label','New experiment');
            
            this.LoadOptions(1) = uimenu(this.LoadMenu,'Label','Yokogawa..',...
                'callback',{@this.setupLoader,'yoko'});
            this.LoadOptions(2) = uimenu(this.LoadMenu,'Label','ImageXpress..',...
                'callback',{@this.setupLoader,'xpress'});
            this.LoadOptions(3) = uimenu(this.LoadMenu,'Label','CellInsight..',...
                'callback',{@this.setupLoader,'bioformat'});
            this.LoadOptions(4) = uimenu(this.LoadMenu,'Label','CellInsight Multi..',...
                'callback',{@this.setupLoader,'bioformat Multi'});
            this.LoadOptions(5) = uimenu(this.LoadMenu,'Label','Excel..',...
                'callback',{@this.setupLoader,'Excel'});

            temph = uimenu(this.LoadMenu,'Label','Image files');
            this.LoadOptions(4) = uimenu(temph,'Label','tifs..',...
                'callback',{@this.setupLoader,'tifs'},'separator','on');
            this.LoadOptions(5) = uimenu(temph,'Label','jpgs..',...
                'callback',{@this.setupLoader,'jpgs'});
            this.LoadOptions(6) = uimenu(temph,'Label','pngs..',...
                'callback',{@this.setupLoader,'pngs'});
            this.LoadOptions(7) = uimenu(temph,'Label','Custom..',...
                'callback',{@this.setupLoader,'custom'});
            
            
            
            this.CloseMenu = uimenu(this.FileMenu,'Label','Close experiment',...
                'callback',@this.closeLoader);
            
            this.ProjectSaveMenu = uimenu(this.FileMenu,'Label','Save Project',...
                'callback',@this.saveProject,'separator','on');
            this.ProjectLoadMenu = uimenu(this.FileMenu,'Label','Load Project',...
                'callback',@this.loadProject,'separator','on');
            
            
            this.HelpMenu = uimenu(this.Figure1,'Label','Help');
            uimenu(this.HelpMenu,'Label','About..',...
                   'callback',@this.aboutcallback);
            uimenu(this.HelpMenu,'Label','Wishlist',...
                   'callback',@this.wishlistCallback);
               
            
        end
        
        %@override - haven't changed anything yet..
        function closeLoader(this,src,evt)
            if ~isempty(this.FigureChoices)
                % deletefcn needs to take care of removing the panels and
                % setting up again
                delete(this.FigureChoices)
                
                % we might want to also delete the WSobject
                % the image bank will also need deleting if it already exists
% %                 delete(this.ImageBankObj)
            end
            
            set(this.Figure1, 'name', 'IALab');            
        end
        
        
        %@Override
        function setupLoader(this,src,evt,imgLoader)
            % This method will be used separately from setLoader below to
            % guide the user to choose the appropriate type of loader for
            % their experiment

            if nargin<4 || isempty(imgLoader)
                imgLoader = 'yoko';
            end
            progressBarAPI('init','Finding images..');
            
            try
                if ischar(imgLoader)
                    % prompt the user to select a folder (or XML file?) from which to
                    % create a ParserYokogawa object
                    % in time, this part will be able to choose or detect what type
                    % of imgLoader has been selected by the user, but for now the CV7000
                    % is the only one required
                    switch imgLoader
                        case 'bioformat'
                            [FileName,PathName] = uigetfile('*.*','Select the CellInsight file');
                            imgLoader = ParserBioFormats(fullfile(PathName, FileName));
                        case 'bioformat Multi'
                            motherDir = uigetdir();

                            imgLoader = ParserMultiPlate();
                            
                            folderNames = az_getSubFolders(motherDir);
                            
                            for i = 1:length(folderNames)
                                deepestFolderName = az_getDeepestChildFolderName([motherDir '\' folderNames{i}]);
                                
                                imgLoader.addParser(ParserBioFormats.fromFolder([motherDir '\' deepestFolderName], 'C01'));
                            end
                            
                        case 'Excel'
                            imgLoader = ParserExcelHTS.browseForFile('*.xls');
                        case 'xpress'
                            imgLoader = ParserXpress.browseForFile();
                        case 'tifs'
                            imgLoader = ParserTrueColour.browseForFile({'*.tif','*.tiff'});
                        case 'jpgs'
                            imgLoader = ParserTrueColour.browseForFile({'*.jpg','*.jpeg'});
                        case 'pngs'
                            imgLoader = ParserTrueColour.browseForFile('*.png');
                        case 'custom'
                            imgLoader = ParserTrueColour.customPattern();
                        otherwise
                            imgLoader = ParserYokogawa.browseForFile();
                    end
                end
            catch me
                rethrow(me);
%                 msgbox('Encountered problem opening experiment')
%                 imgLoader = [];
            end

            if isempty(imgLoader)
                % do nothing
                % will want to display a message at some point
                progressBarAPI('finish');
                return
            end

            % now that we have an imgLoader object, use that to provide the ChoicePanel object
            % to populate the FigureLeft region.

% %             wh = SpinWheel('Setting up..');
            progressBarAPI('init','Setting up..');
            drawnow();
            setLoader(this,imgLoader);
% %             delete(wh);
            progressBarAPI('finish');
        end
        
        %@override
        function getNewImage(this,src,evt)
            if nargin>1 && isequal(src,this.FigureChoices)
                % comes from the selection triggered event, check for auto
                % load
                if ~this.AutoLoad
                    return
                end
            end

            progressBarAPI('init','Loading image..')
            
            imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);

            % as well as the actual image for display, in the background we
            % also want to store the relevant empty 3DnC object so that it
            % can be added to the set of current images for segmentation
            
            imObj = imObj(~cellfun(@isempty,imObj));
            
            emptyObj = this.LoaderObj.getCurrentEmptyImage(this.FigureChoices);
            
            % the objects are now cell arrays in preparation for passing
            % multiple images at a time
            
            for ii = 1:numel(imObj)
                
                %-- Adam: why emptyObj??
                this.FigureTabs.sendToDisplay(imObj{ii},emptyObj{ii});
%                 this.FigureTabs.sendToDisplay(imObj);
                
                % at some point will want to toggle the open new tabs part
                % here for ii>1
            end
            
            progressBarAPI('finish')

        end
        
        %@override
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
                delete(this.WSObj)
            end
            
            % Generate the style of GUI from a method of the loader object
            this.FigureChoices = this.LoaderObj.getChoiceGUI(this.LeftPanel);
            
            currtitles = get(this.LeftPanel,'TabTitles');
            currtitles{end} = 'Browser';
            set(this.LeftPanel,'TabTitles',currtitles)
            
            % check if the workflow has already been defined
            if ~isempty(this.FlowObj)
                this.FlowObj.addParser(this.LoaderObj);
            end
            
            aString = sprintf('IA Explorer v2.1 - %s', this.LoaderObj.getTitle());
            set(this.Figure1, 'name', aString);
            
            this.WSObj = ImageWorkspace(this.FigureLeft);
            % add the bank button to the DisplayManager from here
            if isempty(this.WSButton)
                this.WSButton = uicontrol('parent',this.FigureTabs.AddBox,'style','pushbutton',...
                    'String','Add to Test Images','callback',@this.workspacecallback);
                temp = get(this.FigureTabs.AddBox,'children');
                tempwids = get(this.FigureTabs.AddBox,'widths');
                
                if numel(temp)>=2
                    set(this.FigureTabs.AddBox,'children',temp([2,1,3:end]));

                    tempwids(end-1:end) = [100,-1];
                end
                set(this.FigureTabs.AddBox,'widths',tempwids)
            end

            
            this.WSLstn = addlistener(this.FigureTabs,'addToWorkspace',@this.sendToBank);
            this.DisplayFromWSLstn = addlistener(this.WSObj,'displayFromWorkspace',@this.dispFromBank);
            this.DirectBankLstn = addlistener(this.WSObj,'directBank',@this.directBankCallback);
            
            set(this.FigureLeft,'heights',[-1,100]);
            
            
            resetContrast(this)
            
            % also need to check - if we have a WorkFlow loaded, then the
            % parser should be replaced
            if ~isempty(this.FlowObj)
                this.FlowObj.addParser(this.LoaderObj);
            end
            
        end
        
        function sendToBank(this,src,evt)
            % simply pass the data to the image bank
            addImage(this.WSObj,evt.data.im,evt.data.cdata);
        end

        function dispFromBank(this,src,evt)
            % get the empty image object from the event data, and then
            % create the display image using the current display mode, as
            % in getNewImage above.
            progressBarAPI('init','Retrieving image..')
            
            emptyImObj = evt.data; % might not actually be empty, but doesn't matter..

            % get the channel and zslice from the choices panel, rather
            % than being what the image was when it was banked.
            
            % there won't be a zslice option for many parsers, so it
            % shouldn't be assumed here
            if isa(this.LoaderObj,'ParserHCB')
                if any(strcmpi('channel',this.FigureChoices.IC.labels))
                    cc = get(this.FigureChoices.IC,'channel');
                else
                    cc = [];
                end
                if any(strcmpi('zslice',this.FigureChoices.IC.labels))
                    zz = get(this.FigureChoices.IC,'zslice');
                else
                    zz = [];
                end
                switch this.FigureChoices.blendMode
                    case 0
                        imObj = emptyImObj.getImage2D(cc,zz);
                    case 1
                        imObj = emptyImObj.getImageC2D(zz);
                    case 2
                        imObj = emptyImObj.getImage3D(cc);
                    case 3
                        imObj = emptyImObj;
                    case 4
                        zz = get(this.FigureChoices.IC,'zslice');
                        imObj = emptyImObj.getImageC2D(zz);
                    case 5
                        imObj = emptyImObj;
                    otherwise
                        error('Unknown display mode')
                end
            else
                imObj = emptyImObj;
            end

            this.FigureTabs.sendToDisplay(imObj,emptyImObj);
            
            progressBarAPI('finish')
        end

        

        function workspacecallback(this,src,evt)
            % lots of direct referencing of DisplayManager properties -
            % would be more robust to define DisplayManager methods for
            % doing this
            
            index = this.FigureTabs.getCurrentIndex();

            if index==0 || index>numel(this.FigureTabs.DisplayObjects)
                return
            end

            cdata = rangeNormalise(this.FigureTabs.DisplayObjects{index}.getThumbnail(100));
            imObj = this.FigureTabs.ImageTemplateObjects{index};
            
% %             imObj = this.getCurrentDisplayImage();
            addImage(this.WSObj,imObj,cdata);
            
        end
        
        function imObj = getCurrentDisplayImage(this,src,evt)
            % lots of direct referencing of DisplayManager properties -
            % would be more robust to define DisplayManager methods for
            % doing this
            
            index = this.FigureTabs.getCurrentIndex();

            if index==0 || index>numel(this.FigureTabs.DisplayObjects)
                imObj = [];
                return
            end

%             cdata = rangeNormalise(this.FigureTabs.DisplayObjects{index}.getThumbnail(100));
            imObj = this.FigureTabs.ImageTemplateObjects{index};

%             addImage(this.WSObj,imObj,cdata);
            
        end
        
        function directBankCallback(this,src,evt)
            % pass the currentimage directly to the workspace, without
            % displaying
            % at the moment there won't be a thumbnail for this, but
            % perhaps something should be displayed?
            
            
            imObj = this.LoaderObj.getCurrentEmptyImage(this.FigureChoices);
            
            progressBarAPI('finish')
            progressBarAPI('init','Getting images',numel(imObj))
            
            for ii = 1:numel(imObj)
%                 cdata = rand(50,50,3); % change this to be more appropriate when have the chance
                cdata = imObj{ii}.getThumbnail();
                addImage(this.WSObj,imObj{ii},cdata);
                
                progressBarAPI('increment');
            end
            
            progressBarAPI('finish');
        end
        
        function varargout = addWorkflow(this,flowObj)
            this.FlowObj = flowObj;
            
            % NOTE - TO DO
            % this could all be done from within a WorkFlow method,
            % allowing it to be modified for a particular style
            % To do this, first need to assess how many of the callbacks
            % are for HCExplorer methods, and how many are for HCWorkFlow
            % methods.
            
            
            % perhaps here is where the options should be added to the menu
            this.AnalysisMenu = uimenu(this.Figure1,'Label',this.FlowObj.Name);
            uimenu(this.AnalysisMenu,'Label','Set Output Folder',...
                'callback',@this.chooseOutputFolder);
            uimenu(this.AnalysisMenu,'Label','Load IA Settings',...
                'callback',@this.loadSettingsCallback)
            uimenu(this.AnalysisMenu,'Label','Save IA Settings',...
                'callback',@this.saveSettingsCallback)
            this.CalibrationMenu = uimenu(this.AnalysisMenu,'Label','Interactive Calibration',...
                   'callback',@this.calibrateSegmentation,'separator','on');
            uimenu(this.AnalysisMenu,'Label','Refresh Test Images',...
                'callback',@this.refreshTestImages)
            uimenu(this.AnalysisMenu,'Label','Run Batch Processing',...
                'callback',@this.runBatch)
            
            uimenu(this.AnalysisMenu,'Label','Information',...
                   'callback',@(src,evt)IAHelp(),'separator','on');
            
            % two possibilities
            % - workflow has a parser that needs to be transferred over
            % - GUI already has a parser that should be applied to the
            %   workflow (this should be the dominant behaviour)
            
            if ~isempty(this.LoaderObj)
                this.FlowObj.addParser(this.LoaderObj);
            elseif ~isempty(this.FlowObj.BatchParser)
                this.setLoader(this.FlowObj.BatchParser.ParserObj);
            end
            
            if nargout>0
                varargout{1} = this;
            end
            
        end
        
        function chooseOutputFolder(this,src,evt)
            fol = uigetdir(cd,'Choose folder to store results');
            
            if isempty(fol) || (isnumeric(fol))
                return
            end
            
            this.FlowObj.setOutputFolder(fol);
        end
        
        function calibrateSegmentation(this,src,evt)
            % for now src and evt aren't used, but want them there in case
            % we want to distinguish between GUI and command line
            % invocation.
            
            this.closeSegGUI();
            
            if isempty(this.LoaderObj)
                msgbox('Need to load an experiment first')
                return
            end
            
%             if isempty(this.SegGUIObj)
%                 newPanel = uix.Panel('parent',this.PanelLeft);
                
            % if the image bank is empty, prompt to use the current
            % selection
            
            imobjs = this.WSObj.ImObjList;

            if isempty(imobjs)
                % if nothing in the workspace, choose the current
                % display selection
                imobjs = this.getCurrentDisplayImage();
                if isempty(imobjs)
                    msgbox('No images to run calibration on')
                    return
                end
                imobjs = {imobjs};
            end

            % try adding directly
            this.SegGUIObj = this.FlowObj.runCalibration(imobjs,this.LeftPanel,this.FigureTabs);
%             end
            currtitles = get(this.LeftPanel,'TabTitles');
            currtitles{end} = 'Image Analysis';
            set(this.LeftPanel,'TabTitles',currtitles,'Selection',2)
            
            % change the menu entry to close the calibration GUI
            set(this.CalibrationMenu,'Label','Close calibration','callback',...
                @this.closeCalibration)
            
        end
        
        function closeCalibration(this,src,evt)
            delete(this.SegGUIObj)
            
            % change the menu entry to open the calibration GUI
            set(this.CalibrationMenu,'Label','Interactive Calibration',...
                   'callback',@this.calibrateSegmentation)
            
        end
        
        function refreshTestImages(this,src,evt)
            % load the current workspace images into the segmentation
            % manager
            
            % For now, directly reference the layered methods - but it
            % might be best to implement something in the WorkFlow class
            % that does this
            
            imobjs = this.WSObj.ImObjList;

            if isempty(imobjs)
                % if nothing in the workspace, choose the current
                % display selection
                imobjs = this.getCurrentDisplayImage();
                if isempty(imobjs)
                    msgbox('No images to run calibration on')
                    return
                end
                imobjs = {imobjs};
            end

            % if there are no images, want to do nothing?
            if ~isempty(imobjs)
                this.FlowObj.SegMngrObj.supplyInputImages(imobjs);
            end
        end
        
        function saveSettingsCallback(this,src,evt)
            % have a callback method here rather than directly calling the
            % workflow function, so that errors can be handled in the GUI
            
            [fileName,pathName] = uiputfile('*.json');
            
            % in the dialog, the choice isn't limited to the json extension
            
            % sort out error handling later
            this.FlowObj.SegMngrObj.saveSettings(fullfile(pathName,fileName)); % use the default save settings
            
        end
        function loadSettingsCallback(this,src,evt)
            % have a callback method here rather than directly calling the
            % workflow function, so that errors can be handled in the GUI
            
            [fileName,pathName] = uigetfile('*.json');
            
            % sort out error handling later
            this.FlowObj.SegMngrObj.loadSettings(fullfile(pathName,fileName)); % use the default save settings
            
            % this where the SegGUI is stored, so that needs updating with
            % the new settings here
            
            if ~isempty(this.SegGUIObj)
                this.SegGUIObj.populateSettings(); % the seg GUI should already have a reference to SegMngrObj
            end
        end
        
        function closeSegGUI(this,src,evt)
            if ~isempty(this.SegGUIObj)
                % close it first?
                delete(this.SegGUIObj)
                this.SegGUIObj = [];
            end
        end
        
        function runBatch(this,src,evt)
            % close all the open images and run in batch mode
            % still need to decide whether this will run while open, or if
            % everything will close and then be opened up again
            %
            % As long as it CAN be reopened, nothing wrong with running
            % within HCExplorer
            
            if ~yesnogui('t','Run Batch?','s','Sure you want to close the images and run batch processing?');
                return
            end
            
            parRun = yesnogui('t','Use multiple cores?','s',...
                'Run using multiple cores? This may have a large memory requirement, and no progress will be displayed');
            
            this.FigureTabs.deletePanel([],[],'all');
            
            % probably also want to close the segmentation settings panel
            % and empty the WorkSpace
            % do this later..
            
            drawnow();
            
            minimiseFigure(this.Figure1)
            
            % call the batch run from the WorkFlow
            if parRun
                % create a parallel pool if none is existing
                if isempty(gcp)
                    parpool;
                end
                this.FlowObj.parRunBatch();
            else
                this.FlowObj.runBatch();
            end
            
            
            % at the end, automatically add the QC loading button to the
            % GUI
            this.addQCLoadButton();
        end
        
        function varargout = addQCLoadButton(this,src,evt)
            % add the QC loading button to the choices GUI
            try
                bbox = this.FigureChoices.ButtonBox;
            catch
                msgbox('QC not added for this parser GUI yet')
                return
            end
            
            if isempty(this.QCLoadButton)
                this.QCLoadButton = uicontrol('parent',bbox,'style','pushbutton',...
                    'string','Load QC Image','callback',@this.loadQCImage);
            end
            
            if isempty(this.IndividualQCMenu)
                this.IndividualQCMenu = uimenu(this.AnalysisMenu,'Label','Show QC individually',...
                    'callback',@this.toggleiQC,'Checked','on');
                % if possible, this should be moved above the help/information
                % menu entry.
            end
            
            if nargout>0
                varargout{1} = this;
            end
        end
        
        function removeQCLoadButton(this,src,evt)
            if ~isempty(this.QCLoadButton)
                delete(this.QCLoadButton)
                this.QCLoadButton = [];
            end
        end
        
        function loadQCImage(this,src,evt)
            % load the image, and then the label matrices and overlay them
            % in the display
            
            
            imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);
            L = this.FlowObj.getLabelData(this.FigureChoices);
            
            % do we want to show the QC individually?
            iQC = strcmpi(get(this.IndividualQCMenu,'Checked'),'on');
            
            if iQC && isa(this.FlowObj.SegMngrObj,'SegmentationManager')
                % display individual segmentation results one by one, along
                % side the relevant image channels used for the
                % segmentation
                inchan = this.FlowObj.SegMngrObj.ProcInputChannels;
                outlab = this.FlowObj.SegMngrObj.ProcOutputLabels;
                
                % also need to get the image data and colour channels ready
                % to create separate image objects
                imdata = imObj{1}.getDataC2D();
                cols = imObj{1}.NativeColour;
                
                wh = SpinWheel('Setting up display..');
                
                procOptions = this.FlowObj.SegMngrObj.InputProcessing;
                
                for ii = 1:numel(this.FlowObj.SegMngrObj.ProcArray)
                    
                    if numel(procOptions)>=inchan{ii} && any(strcmpi(procOptions(inchan{ii}),'max') | strcmpi(procOptions(inchan{ii}),'mean'))
                        comboImObj = cAnnotatedImage(...
                            cImage2DnC([],[],cols(inchan{ii}),inchan{ii},imObj{1}.PixelSize(1:2),...
                            imObj{1}.Tag,imdata(inchan{ii})),...
                            cMixedLabel2DnC(L(outlab{ii})));
                    else
                        % for the moment, channel information is just
                        % ignored..
                        % this prevents 3D QC being automatically projected
                        % into 2D
                        if isa(imObj{1},'cImage2DnC')
                            imsiz = [imObj{1}.ImSize(1:2),1];
                        else
                            imsiz = imObj{1}.ImSize(1:3);
                        end
                        comboImObj = cAnnotatedImage(imObj{1},cMixedLabel2DnC(L(outlab{ii}),imsiz));
                    end
                    
                    dispObj = this.FigureTabs.sendToDisplay(comboImObj);
                    
                    dispObj.hideToolbar();
                end
                
                delete(wh)
                
            else
%                 for ii = 1:numel(imObj)
                    % haven't completed the 3DnC label array
                    % or indeed the combined point and region label class

                    % also, this currently makes the assumption that the label data
                    % is stored as the labelData field
    %                 comboImObj = cAnnotatedImage(imObj{1},cLabel2DnC(L.labelData));
                    comboImObj = cAnnotatedImage(imObj{1},cMixedLabel2DnC(L));
                    
                    wh = SpinWheel('Setting up display..');
                    this.FigureTabs.sendToDisplay(comboImObj);
                    
                    delete(wh)
%                 end
            end
        end
        
        function toggleiQC(this,src,evt)
            iQC = strcmpi(get(this.IndividualQCMenu,'Checked'),'on');
            
            if iQC
                set(this.IndividualQCMenu,'Checked','off')
            else
                set(this.IndividualQCMenu,'Checked','on')
            end
        end
        
        function saveProject(this,src,evt)
            % get the filename and then save the workflow
            fileName = uiputfile('*.mat','Choose save file name');
            
            if isempty(fileName) || isnumeric(fileName)
                return
            end
            
            this.FlowObj.saveProject(fileName);
        end
        
        function loadProject(this,src,evt)
            fileName = uigetfile('*.mat','Choose a file to load project from');
            
            if isempty(fileName) || isnumeric(fileName)
                return
            end
            
            if ~isempty(this.FlowObj)
                this.FlowObj.loadProject(fileName);
            else
                this.addWorkflow(HCWorkFlow.buildFromFile(fileName));
            end
            
            if isempty(this.FlowObj.BatchParser) && ~isempty(this.LoaderObj)
                this.FlowObj.addParser(this.LoaderObj);
            elseif ~isempty(this.FlowObj.BatchParser)
                % by default, loading a project should replace any
                % experiments currently open
                this.setLoader(this.FlowObj.BatchParser.ParserObj);
            end
            
        end
    end
end