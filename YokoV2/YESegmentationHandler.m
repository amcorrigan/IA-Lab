classdef YESegmentationHandler < handle
    % manages segmentation in YE2
    % 
    % In this respect, it performs a similar role to FigureDisplayList for
    % display objects
    % The primary function of this class is to act as an adapter between
    % the segmentation classes (containing the algorithms) and the displays
    % (which handle image classes)
    % In this regard, would it be better to export the segmentation class
    % and the choice of channels to a smaller and more specific class?
    
    % This is the combined GUI and implementation for segmentation -
    % adapter which feeds the correct channels into each segmentation class
    % (currently only one supported), and organises the output into label
    % classes
    % it also has the GUI part - but since the images have to come from
    % outside anyway (and thus the run button triggers an event rather than
    % calling performSegmentation directly), it might make sense to
    % separate these into two classes - the managing and the GUI - as has
    % been done in other cases.
    
    % Then when it comes to getting measurements from the labels, a similar
    % approach can be adopted having a MeasurementManager handling the
    % image and label objects and returning a data structure
    
    % Another part to consider is whether as part of a pipeline, a label
    % object can start off by being defined by the seg object which
    % generates it (much like an image being defined by the file locations)
    % so that it is only calculated when it is needed.  In order to do this
    % the label would need to flag to this class that the relevant
    % segmentation process needs to be run using the appropriate image
    % data.
    % Then if the image data has been changed in between there needs to be
    % a way of clearing all the labels, much like the cache in the image
    % loader
    % Therefore in order for this to work, the image, label and data all
    % need to be stored together with the segmentation and measurement
    % objects as a data package, and perhaps an overarching master class
    % could be in control of a segmanager, measmanager and combined GUI
    
    % The design of this will be similar in principle to a results
    % explorer, which will bring together image, segmentation, and results
    % browsing - the difference will be that rather than having to
    % calculate the results (labels and measurements), they will be stored
    % in a binary file or a database.  With this in mind, it might be worth
    % sketching out the architecture of the post-analysis browser to ensure
    % the interactive setup is consistent.
    
    properties
        ParentHandle
        
        MainPanel
        MainHBox
        DescriptionPanel
        
        SettingsPanel
        SettingsObj
        SettingsHBox
        
        SegObj
        
        ChanChoice
        RunButton
        
        TotalNumChan = 1;
        
        ProcMenu
        LoadProc
        ProcFactory
    end
    events
        runClicked
    end
    methods
        function this = YESegmentationHandler(parenth,numChan)
            
            % This is where the panel for user interaction will appear
            % but don't put anything there until we've got an algorithm to
            % run
            if nargin>0 && ~isempty(parenth)
                this.ParentHandle = parenth;
            end
            if nargin>1 && ~isempty(numChan)
                this.TotalNumChan = numChan;
            end
            
            % build the architecture of the display before it is made
            % visible
% %             this.MainPanel = uix.BoxPanel('Title','Segmentation');
            this.MainPanel = CollapsePanel([],'Title','Segmentation');
            this.MainHBox = uix.HBox('parent',this.MainPanel);
            this.DescriptionPanel = uix.BoxPanel('Title','Description','parent',this.MainHBox,...
                'TitleColor',[0.5,0.9,1]);
            
            this.SettingsPanel = uix.BoxPanel('Title','Settings','parent',this.MainHBox,...
                'TitleColor',[0.5,0.9,1]);
            
            set(this.MainHBox,'widths',[-1,-2.5])
            % the settings panel is broken down into two or three parts, the
            % specific tuning parameters on one side, and the choice of
            % input channels and naming of output channels and running on
            % the other.
            this.SettingsHBox = uix.HBox('parent',this.SettingsPanel,'spacing',10);
            
            this.setupMenuEntry();
        end
        
        function setupMenuEntry(this)
            fig = getFigParent(this.ParentHandle);
            if isempty(fig)
                error('can''t find parent figure! This shouldn''t happen')
            end
            
            this.ProcMenu = uimenu(fig,'Label','Image Processing');
            this.LoadProc = uimenu(this.ProcMenu,'Label','Load processing module');
            this.ProcFactory = ProcessFactory(this.LoadProc,@this.loadSegmenter);


        end
        
        function loadSegmenter(this,src,evt,ind)

            segobj = this.ProcFactory.getSegObj(ind);
            addAlgorithm(this,segobj);

        end
        
        function addNumChan(this,numChan)
            this.TotalNumChan = numChan;
        end
        
        function addAlgorithm(this,segObj)
            % at the moment, only one algorithm is allowed at a time
            % this will probably change in version 3, to allowed pipelines
            % and workflows
            
            if ~isa(segObj,'AZSeg')
                error('Only AZSeg interface classes are appropriate')
            end
            
            
            this.SegObj = segObj;
            
            % add the description to the description panel
            addDescription(this);
            
            % set up the sliders and tuning parameters here
            % this might be slightly different to the settingsUI approach
            % because the panel already exist and have contents
            % the settings adjuster should be a separate class, which
            % populates a panel on here with the appropriate settings, and
            % knows how to update the segmentation object.
            % The segmentation object in turn needs to be the one that
            % specifies what style of settings adjuster to bring up, and
            % also how many input and output channels are required
            
            % first make sure the SettingsHBox is empty
            delete(get(this.SettingsHBox,'Children'))
            
            this.SettingsObj = this.SegObj.defaultSettingsUI(this.SettingsHBox);
            
            % also add the channel selector and run button
            tempvbox = uix.VBox('parent',this.SettingsHBox);
            uicontrol('style','text','parent',tempvbox,'string','Channel Selection');
            
            menustr = num2cell(num2str((1:this.TotalNumChan)'),2);
            for ii = 1:this.SegObj.NumInputChan
                temphbox = uix.HBox('parent',tempvbox);
                uicontrol('style','text','string',sprintf('%s input',num2ordinal(ii)),...
                    'parent',temphbox);
                this.ChanChoice(ii) = uicontrol('style','popupmenu','string',menustr,...
                    'value',min(ii,this.TotalNumChan),'parent',temphbox);
            end
            uix.Empty('parent',tempvbox);
            this.RunButton = uicontrol('style','pushbutton','String','RUN!',...
                'callback',@this.runSegmentation,'parent',tempvbox);
            
            % then make the display visible
            set(this.MainPanel,'parent',this.ParentHandle);
            if this.MainPanel.Minimized
                this.MainPanel.toggleMinimized;
            end
            
            % this makes the assumption that it's a VBox, and that there
            % are only two children
            set(this.ParentHandle,'Heights',[-2.5,-1]);
            
        end
        
        
        function addDescription(this)
            % add or update the description in the Panel
            
            % Since this doesn't need editing, to begin with try not
            % storing any handles for anything..
            
            edith = get(this.DescriptionPanel,'children');
            if isempty(edith)
                edith = uicontrol('style','edit','parent',this.DescriptionPanel,...
                    'enable','inactive','fontsize',12,'max',20,'min',1,...
                    'HorizontalAlignment','left');
            end
            
            if isa(this.SegObj,'AZSeg')
                set(edith,'String',this.SegObj.getDescription())
            end
            
        end
        
        function runSegmentation(this,src,evt)
            % the idea of this button is to get images from the image bank
            % and run the chosen segmentation on them, then display the
            % results in the main window
            
            % since this manager doesn't know anything about the bank or
            % the display window, it must be done using events and
            % listeners
            
            % first update the algorithm settings
            updateSettings(this.SegObj,this.SettingsObj.Values)
            
            notify(this,'runClicked')
        end
        
        function [labObj,outImObj] = performSegmentation(this,imObj)
            % Only works so far for direct segmentation (ie not using an
            % existing label matrix, eg for cell segmentation after nuclei)
            
            % This needs to know whether the segmentation wants a 2D or 3D
            % image
            % This must be specified by the segmentation class, because
            % nothing else will know..
            
            usechan = cell2mat(get(this.ChanChoice,'Value'));
            
            imdata = imObj.rawdata(usechan); % I think this will break when there is only one channel in the image
            
            L = process(this.SegObj,imdata);
            
            labObj = autoLabelObj(L);
            
        end
    end
end