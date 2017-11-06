classdef WoundExplorer < YEMain
    
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
        function this = WoundExplorer(imgLoader)
            if nargin == 0
                imgLoader = [];
            end;
            
            this = this@YEMain(imgLoader, 'Wound Explorer');
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
            this.IAOption(2) = uimenu(this.IAMenu,'Label','Batch Run',...
                                       'callback',@this.IABatchCallback,...
                                       'Enable', 'Off');
            this.IAOption(3) = uimenu(this.IAMenu,'Label','Fine Tune',...
                                       'callback',@this.IAFineTuneCallback,...
                                       'Enable', 'On', 'Accelerator', 't');
            this.IAOption(4) = uimenu(this.IAMenu,'Label','Export Results to Excel',...
                                       'callback',@this.ExportExcelCallback,...
                                       'Enable', 'On', 'Accelerator', 'e');
            
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
            % 3. IA Fine tune
            icon = imread('iconFineTune.png');
            icon = imresize(im2double(icon), [16 16]);       
            icon(repmat(all(icon<0.05,3),[1,1,3])) = NaN;
                           
            % Create a uipushtool in the toolbar
            uipushtool(this.Toolbar,...
                       'TooltipString','IA fine tune',...
                       'ClickedCallback', @this.IAFineTuneCallback,...
                       'Separator','off',...
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
                            aParser = ParserRGBnMarkup.browseForFile({'*.tif','*.tiff'});
                        case 'jpgs'
                            aParser = ParserRGBnMarkup.browseForFile({'*.jpg','*.jpeg'});
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
            
            aString = sprintf('Wound Healing Explorer - %s', this.LoaderObj.getTitle());
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
    
    % new fucntions created for woundhealing project
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
        
        function IABatchCallback(this,src,evt)
        
            progressBarAPI('init','Please wait', this.aBatchObj.NumImages);
            
            for i = 1:this.aBatchObj.NumImages
                
                progressBarAPI('increment');

                anImageObj = this.aBatchObj.getImage(i);

                [labelOutput, diameter] = az_woundProcessing(anImageObj.ImData);

                woundDiameter = az_woundSize(labelOutput{1}, diameter);
            
                aString = sprintf('%s\\%s_Results.mat', this.aBatchObj.ResultDir, anImageObj.Tag);
                save(aString, 'labelOutput', 'diameter', 'woundDiameter');
                
                this.saveQCView(anImageObj, labelOutput, woundDiameter, anImageObj.Tag);
            end
            
            progressBarAPI('finish');
            
            delete(this.aBatchObj);
        end
        
        function o_overlayed = saveQCView(this, i_anImageObj, i_LabelCell, i_diameter, i_tag)

            anRGBImage = im2uint8(i_anImageObj.getDataC2D());
            
            o_overlayed = az_getQCViewImage(anRGBImage, i_LabelCell, i_diameter);
            
            aString = sprintf('%s\\%s_Overlay.jpg', this.ResultDir, i_tag);
            imwrite(o_overlayed, aString);
        end
        
        function IAResultDirCallback(this,src,evt)
            
            this.aBatchObj = ThroughputTrueColour(this.LoaderObj);
            this.aBatchObj.createResultDir();  
            
            this.ResultDir = this.aBatchObj.ResultDir;
            
            this.LoaderObj.setResultDir(this.ResultDir);
            
            if ~isempty(this.ResultDir)
                set(this.IAOption(2), 'Enable', 'On');
            end
        end
        
        function IAFineTuneCallback(this, src, evt)
            
%             imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);
            imObj = this.FigureTabs.DisplayObjects{1}.ImObj;

            if ~isempty(imObj)
                this.RoiWindow = RegionSelection.loadRegionSelection(imObj);
                addlistener(this.RoiWindow,'TuneMaskDefined',@this.roiTuneMaskCallback);
                addlistener(this.RoiWindow,'ApplyDefined',@this.roiApplyCallback);
            end
        end;
        
        function ExportExcelCallback(this, src, evt)
            
            exportor = SemicolonSeparatedAZExport();
            
            progressBarAPI('init','Please wait', this.aBatchObj.NumImages);

            outputStruct(this.aBatchObj.NumImages).ImageName = '';
            outputStruct(this.aBatchObj.NumImages).ImagePath = '';
            outputStruct(this.aBatchObj.NumImages).WoundArea = NaN;
            outputStruct(this.aBatchObj.NumImages).QCPath = '';
            
            for i = 1:this.aBatchObj.NumImages

                anImageInfo = this.aBatchObj.getImageInfo(i);
            
                aString = sprintf('%s\\%s_Results.mat', this.ResultDir, anImageInfo.Label);
                
                if exist(aString, 'file') == 2
                    F = load(aString);
                    
                    outputStruct(i).ImageName = anImageInfo.Label;
                    outputStruct(i).ImagePath = anImageInfo.FilePath;
                    outputStruct(i).WoundArea = F.woundDiameter;
                    outputStruct(i).QCPath = sprintf('%s\\%s_Overlay.jpg', this.ResultDir, anImageInfo.Label);
                else
                    continue;
                end;

                progressBarAPI('increment');
            end;
            
            aString = sprintf('%s\\All_Results.csv', this.ResultDir);
            exportor.export(outputStruct, false, aString);
            
            progressBarAPI('finish');
        end;        
        
        
        function roiTuneMaskCallback(this, src, evt)

            BW = this.RoiWindow.getROIData;  % retrieve the generated data

%             imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);
            imObj = this.FigureTabs.DisplayObjects{1}.ImObj;
            
            bwWound = az_AssistedSegment2_Wound(imObj.ImData, BW, false);
            
            this.RoiWindow.loadROI(bwWound);
            this.RoiWindow.setROIData(bwWound);
        end
        
        function roiApplyCallback(this, src, evt)

            BW = this.RoiWindow.getROIData;  % retrieve the generated 
            delete(this.RoiWindow);

%             imObj = this.LoaderObj.getSelectedImage(this.FigureChoices);
            imObj = this.FigureTabs.DisplayObjects{1}.ImObj;

            labelOutput{1} = bwlabel(BW);
            
            aString = sprintf('%s\\%s_Results.mat', this.ResultDir, imObj.Tag);
            if exist(aString, 'file') == 2

                F = load(aString);
         
                if numel(F.labelOutput) <= 1
                    [bwDisk, diameter] = az_scaleDisk_WouldHealing(imObj.ImData);
                    labelOutput{2} = bwlabel(bwDisk);
                else
                    labelOutput{2} = F.labelOutput{2};
                end
                
                if isfield(F,'diameter') == true
                    diameter = F.diameter;
                end;
            else
                [bwDisk, diameter] = az_scaleDisk_WouldHealing(imObj.ImData);
                
                labelOutput{2} = bwlabel(bwDisk);
            end
            
            woundDiameter = az_woundSize(BW, diameter);
            
            save(aString, 'labelOutput', 'diameter', 'woundDiameter');
            imObj.setResult(this.saveQCView(imObj, labelOutput, woundDiameter, imObj.Tag));
            
%             this.getNewImage(src,evt);
            this.FigureTabs.sendToDisplay(imObj);
        end
    end
end