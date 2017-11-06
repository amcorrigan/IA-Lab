classdef PelletExplorer < YEMain
    
    properties (SetAccess = protected)
        IAMenu

        LoadOptions
        
        PrevButton
        NextButton
        
        ResultDir = [];
        
        IAOption
        aBatchObj        
        RoiWindow = [];
    end
    
    properties % listeners
        ImshowDoneListener;
    end
    
    methods
        %-- Override
        function this = PelletExplorer(imgLoader)
            if nargin == 0
                imgLoader = [];
            end;
            
            this = this@YEMain(imgLoader, 'Pellet Explorer');
        end
      
        %-- Override
        function setDisplayManager(this)
            aNewContainer = uix.BoxPanel('Padding', 5);
            set(aNewContainer, 'TitleColor', [0.3 0.2 0]);
            set(aNewContainer, 'ForegroundColor', [0 0 0]);
            set(aNewContainer, 'FontWeight', 'Bold');
            set(aNewContainer, 'FontSize', 12);
            
            this.FigureTabs = DisplayManagerBase(this.FigureRight, aNewContainer);
            this.FigureTabs.NewTab = false;
        end
            
        %-- Override
        function setupMenuEntry(this)
            this.FileMenu = uimenu(this.Figure1,'Label','Load');
            this.LoadMenu = uimenu(this.FileMenu,'Label','New experiment');

            this.LoadOptions(1) = uimenu(this.LoadMenu,'Label','tifs..',...
                'callback',{@this.setupLoader,'tifs'},'separator','on');
            this.LoadOptions(2) = uimenu(this.LoadMenu,'Label','jpgs..',...
                'callback',{@this.setupLoader,'jpgs'});
            this.LoadOptions(3) = uimenu(this.LoadMenu,'Label','pngs..',...
                'callback',{@this.setupLoader,'pngs'});
            this.LoadOptions(4) = uimenu(this.LoadMenu,'Label','Custom..',...
                'callback',{@this.setupLoader,'custom'});
            
            this.CloseMenu = uimenu(this.FileMenu,'Label','Close experiment',...
                'callback',@this.closeLoader);
            
            this.IAMenu = uimenu(this.Figure1,'Label','Image Analysis');
            this.IAOption(1) = uimenu(this.IAMenu,'Label','Setup Result Directory',...
                                      'callback',@this.IAResultDirCallback);
            this.IAOption(2) = uimenu(this.IAMenu,'Label','Run Current Image',...
                                       'callback',@this.IASingleImageCallback,...
                                       'Enable', 'Off', 'Accelerator', 'r');
            this.IAOption(3) = uimenu(this.IAMenu,'Label','Batch Run',...
                                       'callback',@this.IABatchCallback,...
                                       'Enable', 'Off', 'Accelerator', 'b');
            this.IAOption(4) = uimenu(this.IAMenu,'Label','Fine Tune',...
                                       'callback',@this.IAFineTuneCallback,...
                                       'Enable', 'On', 'Accelerator', 't');
                                   
            this.HelpMenu = uimenu(this.Figure1,'Label','Help');
            uimenu(this.HelpMenu,'Label','About..',...
                   'callback',@this.aboutcallback);
        end
        
        %-- Override
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
            % 3. About
            icon = imresize(imread('yokoAbout.png'), [16 16]);
            icon = im2double(icon);
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','About',...
                       'ClickedCallback', @this.aboutcallback,...
                       'Separator','on',...
                       'CData', icon);
        end
        
        %-- Override - very diff from YEMain        
        function setupLoader(this,src,evt,aParser)
            % This method will be used separately from setLoader below to
            % guide the user to choose the appropriate type of loader for
            % their experiment

            if nargin<4 || isempty(aParser)
                aParser = 'jpgs';
            end
            progressBarAPI('init','Finding images..');
            
            try
                if ischar(aParser)
                    % prompt the user to select a folder (or XML file?) from which to
                    % create a ParserYokogawa object
                    % in time, this part will be able to choose or detect what type
                    % of imgLoader has been selected by the user, but for now the CV7000
                    % is the only one required
                    switch aParser
                        case 'xpress'
                            aParser = ParserXpress.browseForFile();
                        case 'tifs'
                            aParser = ParserRGBnMarkup.browseForFile({'*.tif','*.tiff','*.TIF','*.TIFF'});
                        case 'jpgs'
                            aParser = ParserRGBnMarkup.browseForFile({'*.jpg','*.jpeg','*.JPG','*.JPEG'});
                        case 'pngs'
                            aParser = ParserRGBnMarkup.browseForFile('*.png');
                        case 'custom'
                            aParser = ParserRGBnMarkup.customPattern();
                    end
                end
            catch me
                rethrow(me);
%                 msgbox('Encountered problem opening experiment')
%                 imgLoader = [];
            end

            if isempty(aParser)
                % do nothing
                % will want to display a message at some point
                progressBarAPI('finish');
                return
            end

            % now that we have an imgLoader object, use that to provide the ChoicePanel object
            % to populate the FigureLeft region.
            progressBarAPI('init','Setting up..');
            drawnow();
            this.setLoader(aParser);
            progressBarAPI('finish');
        end
        
        %-- Override
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
            end
            
            % Generate the style of GUI from a method of the loader object
            %-- This is the GUI which include the 3 buttons at the buttom/
            this.FigureChoices = this.LoaderObj.getChoiceGUI(this.FigureLeft);
            
            aString = sprintf('Pellet Explorer - %s', this.LoaderObj.getTitle());
            set(this.Figure1, 'name', aString);
            
            %-- Add extra buttons for nagiviation.
            ch = this.FigureChoices.ButtonBox.Children;
            ch.Parent = [];
            
            this.PrevButton = uicontrol('style','pushbutton','parent',this.FigureChoices.ButtonBox,...
                                        'String','Previous','callback',@this.buttonPrevCallback);

            ch.Parent = this.FigureChoices.ButtonBox;
                                    
            this.NextButton = uicontrol('style','pushbutton','parent',this.FigureChoices.ButtonBox,...
                                        'String','Next','callback',@this.buttonNextCallback);
            
            set(this.FigureChoices.ButtonBox,'widths',[-1,-1,-1]);      
            
            this.ChoiceLstn = addlistener(this.FigureChoices,'choiceUpdate',@this.getNewImage);
            
            this.ImshowDoneListener = addlistener(this.FigureTabs,'ImshowDone',@this.navButtonEnable);
        end
        
        %-- Override
        function getNewImage(this,src,evt)
            if nargin>1 && isequal(src,this.FigureChoices)
                % comes from the selection triggered event, check for auto
                % load
                if ~this.AutoLoad
                    return
                end
            end

            this.navButtonDisable;           

           imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);

           if isempty(imObj)
               this.navButtonEnable;
               return;
            end;
                
            this.FigureTabs.sendToDisplay(imObj);
        end
        
        %-- Override
        function aboutcallback(this,src,evt)
            AboutWound();
        end
    end
    
    % new fucntions created for pellet project
    methods 
        function buttonPrevCallback(this, src, evt)

            this.FigureChoices.getPrevValues();
            this.getNewImage(src,evt);
        end
        
        function buttonNextCallback(this, src, evt)
            
            this.FigureChoices.getNextValues();
            this.getNewImage(src,evt);
        end        
        
        function navButtonEnable(this, src, evt)
            set(this.NextButton, 'enable', 'on');
            set(this.PrevButton, 'enable', 'on');
            set(this.FigureChoices.ButtonBox.Children, 'enable', 'on');
        end
        
        function navButtonDisable(this, src, evt)
            set(this.NextButton, 'enable', 'off');
            set(this.PrevButton, 'enable', 'off');
            set(this.FigureChoices.ButtonBox.Children, 'enable', 'off');
        end
        
        function IASingleImageCallback(this, src, evt)

            progressBarAPI('init','Please wait');
            
            anImageObj = this.LoaderObj.getSelectedImage(this.FigureChoices);
        
            this.processImage(anImageObj);
        
            this.getNewImage(src,evt);

            progressBarAPI('finish');
        end

        function processImage(this, anImageObj)
            
            labelPellet = az_segmentPellet2(anImageObj.ImData);

            this.calculateFeatures(anImageObj.ImData, labelPellet, anImageObj.Tag);
            
            this.saveQCView(anImageObj, labelPellet, anImageObj.Tag);
        end
        
        function IABatchCallback(this,src,evt)
        
            progressBarAPI('init','Please wait', this.aBatchObj.NumImages);
            
            for i = 1:this.aBatchObj.NumImages
                
                progressBarAPI('increment');

                anImageObj = this.aBatchObj.getImage(i);                
                this.processImage(anImageObj);
            end
            
            progressBarAPI('finish');
            
            delete(this.aBatchObj);
        end
        
        function calculateFeatures(this, i_anImageObj, i_LabelPellet, i_tag)
        
            hsi = rgb2hsi(i_anImageObj);
            
            %
            STATS = regionprops(i_LabelPellet{1}, hsi(:, :, 2), 'MeanIntensity');
            meanSat = [STATS.MeanIntensity];
            
            statSat = mean(meanSat);
        
            %
            STATS = regionprops(i_LabelPellet{1}, hsi(:, :, 3), 'MeanIntensity', 'Area');
            meanInt = [STATS.MeanIntensity];
        
            statInt = mean(meanInt);

            area = [STATS.Area];
            statArea = mean(area);
            
            %
            exportor = SemicolonSeparatedAZExport();

            outputStruct(1).ImageName = i_tag;
            outputStruct(1).AveIntensity = statInt;
            outputStruct(1).AveSaturation = statSat;
            outputStruct(1).Area = statArea;
            outputStruct(1).QCPath = sprintf('%s\\%s_Overlay.jpg', this.ResultDir, i_tag);
            
            aString = sprintf('%s\\%s_Results.csv', this.ResultDir, i_tag);
            exportor.export(outputStruct, false, aString);
            
            delete(exportor);
            
            %-- Single Pellet Info
            exportor = SemicolonSeparatedAZExport();

            outputStruct(length(meanSat)).Index = length(meanSat);
            outputStruct(length(meanSat)).ImageName = '';
            outputStruct(length(meanSat)).AveIntensity = NaN;
            outputStruct(length(meanSat)).AveSaturation = NaN;
            outputStruct(length(meanSat)).Area = NaN;
            outputStruct(length(meanSat)).QCPath = '';
            
            for i = 1:length(meanSat)
                outputStruct(i).Index = i;
                outputStruct(i).ImageName = i_tag;
                outputStruct(i).AveIntensity = meanInt(i);
                outputStruct(i).AveSaturation = meanSat(i);
                outputStruct(i).Area = area(i);
                outputStruct(i).QCPath = sprintf('%s\\%s_Overlay.jpg', this.ResultDir, i_tag);
            end;
            
            aString = sprintf('%s\\%s_Individual_Results.csv', this.ResultDir, i_tag);
            exportor.export(outputStruct, false, aString);
            
            delete(exportor);
        end
            
        function o_overlayed = saveQCView(this, i_anImageObj, i_LabelPellet, i_tag)

            anRGBImage = im2uint8(i_anImageObj.getDataC2D());
            o_overlayed = imoverlay(anRGBImage, bwperim(i_LabelPellet{1}~=0), [0 1 0], 4);  
            
            STATS = regionprops(i_LabelPellet{1}, 'Centroid');
            for i = 1:length(STATS)
                aString = sprintf('%d',i);
                o_overlayed = insertText(o_overlayed, ...
                                         [STATS(i).Centroid(1) STATS(i).Centroid(2)], ...
                                         aString, ...
                                         'AnchorPoint', 'Center',...
                                         'FontSize', 36, ...
                                         'BoxColor', 'yellow', ...
                                         'TextColor', 'blue');
            end
            
            aString = sprintf('%s/%s_Overlay.jpg', this.ResultDir, i_tag);
            imwrite(o_overlayed, aString);
        end
        
        function IAResultDirCallback(this,src,evt)
            
            this.aBatchObj = ThroughputTrueColour(this.LoaderObj);
            this.aBatchObj.createResultDir();  
            
            this.ResultDir = this.aBatchObj.ResultDir;
            
            this.LoaderObj.setResultDir(this.ResultDir);
            
            if ~isempty(this.ResultDir)
                set(this.IAOption(2), 'Enable', 'On');
                set(this.IAOption(3), 'Enable', 'On');
            end
        end
        
        function IAFineTuneCallback(this, src, evt)
            
            progressBarAPI('init','Please wait');

            anImageObj = this.FigureTabs.DisplayObjects{1}.ImObj;

            if ~isempty(anImageObj)
                if ~isempty(anImageObj.ImDataResult)

                    this.RoiWindow = RegionDualSelection.loadRegionSelection(anImageObj);

                    %-- This is where you need to replace to a personalised
                    %-- function.
                    labelPellet = az_segmentPellet2(anImageObj.ImData);
                    
                    
                    anImageObj.setResult(this.saveQCView(anImageObj, labelPellet, anImageObj.Tag));
                    
                    this.RoiWindow.loadROI(labelPellet{1}~=0); 
                    this.RoiWindow.setROIData(labelPellet{1}~=0);

                    addlistener(this.RoiWindow,'ApplyDefined',@this.roiApplyCallback);
                end;
            end;
            
            progressBarAPI('finish');
        end;
       
        function roiApplyCallback(this, src, evt)

            BW = this.RoiWindow.getROIData;  % retrieve the generated 
            delete(this.RoiWindow);

            anImageObj = this.FigureTabs.DisplayObjects{1}.ImObj;

            labelPellet{1} = bwlabel(BW);
            
            this.calculateFeatures(anImageObj.ImData, labelPellet, anImageObj.Tag);
            
            anImageObj.setResult(this.saveQCView(anImageObj, labelPellet, anImageObj.Tag));
            
            this.FigureTabs.sendToDisplay(anImageObj);
        end        
        
        
    end
end