classdef HCWorkFlow < handle
    % workflow manager for an image analysis experiment
    %
    % this handles both the calibration/tuning and the batch processing, as
    % separate methods
    %
    % Currently, want to have the choice of using the OO Framework of
    % segmentation and measurement classes, or simply providing function
    % handles which have a defined input/output interface.
    %
    % The WorkFlow is added to HCExplorer - ie the GUI should be able to
    % call the various components of the WorkFlow, rather than the other
    % way around.  Therefore, this class doesn't need to know about the
    % WorkSpace (formerly ImageBank), because this WorkFlow should be able
    % to be run without it.
    
    properties
        Name = 'Analysis';
        BatchParser
        SegMngrObj
        MeasMngrObj
        ExportMngrObj
        
        CustomFunctions = {};
        
%         SegGUIObj
        
        CancelBatch = false;
        
        QCResolution = 0.1;
        QCWholeImage = true;
    end
    methods
        function this = HCWorkFlow(segMngr, measMngr, exportMngr,batchParser,displayname)
% %             this.BatchParser = batchParser;
            if nargin>0 && ~isempty(segMngr)
                this.SegMngrObj = segMngr;
            end
            if nargin>1 && ~isempty(measMngr)
                this.MeasMngrObj = measMngr;
            end
            if nargin>2 && ~isempty(exportMngr)
                this.ExportMngrObj = exportMngr;
            end
            
            if nargin>3 && ~isempty(batchParser)
                this.addParser(batchParser)
            end
            if nargin>4 && ~isempty(displayname) && ischar(displayname)
                this.Name = displayname;
            end
            
        end
        
        function addParser(this,batchParser)
            if ~isa(batchParser,'ThroughputParser')
                try
                    batchParser = batchParser.getBatchParser();
                catch ME
                    error('Automatic batch parser generation not completed yet')
                end
            end
            
            this.BatchParser = batchParser;
            
            this.setPixelSize(this.BatchParser.getPixelSize);
        end
        
        function varargout = runCalibration(this,imObjs,parentHandle,dispMngr)
            
            if nargin<4 || isempty(dispMngr)
                dispMngr = DisplayManager();
            end
            if nargin<3 || isempty(parentHandle)
                parentHandle = gfigure();
            end
            
            % This calibration isn't possible without the segmentation
            % manager (ie if a function handle is supplied instead), but we
            % probably still want to be able to run the analysis and show
            % the result
            
            if isa(this.SegMngrObj,'function_handle')
                error('Function handle style not finished yet')
            end
            
            if isa(this.SegMngrObj,'AZSeg')
                % create a temporary manager to wrap around the raw
                % segmentation class
                
                useSegMngr = SegmentationManager();
                useSegMngr.addProcess(this.SegMngrObj,Inf,[]); % Inf to specify all channels are passed, without knowing in advance how many
                
                
            else
                % use the SegmentationManager already in the workflow
                useSegMngr = this.SegMngrObj;
            end
            
            % load the images into the segmentation manager
            useSegMngr.supplyInputImages(imObjs);

            % generate the segmentation GUI and show it
            segGUIObj = SegManGUI(useSegMngr,parentHandle,dispMngr);
            
            if nargout>0
                varargout{1} = segGUIObj;
            end
        end
        
        function runBatch(this,idxlist)
            % do the segmentation, measurement and export for every image
            
            % create a progress bar and lock it to prevent any others
            % showing up
            if isempty(this.BatchParser)
                error('Need to specify the location and type of images (supply parser info)')
%                 return
            end
            
            if nargin<2 || isempty(idxlist)
                idxlist = 1:this.BatchParser.getNumImages;
            end
            idxlist = idxlist(:)';
            
            this.CancelBatch = false;
            
            numImages = numel(idxlist);
            progressBarAPI('forcefinish')
            progressBarAPI('setstyle',@SpinProgCancel)
            progressBarAPI('init','Running batch analysis',numImages)
            progressBarAPI('lockcaller');
            
            cancelhandle = progressBarAPI('getcancelhandle');
            if ~isempty(cancelhandle)
                templstn = addlistener(progressBarAPI('getcancelhandle'),'cancel',@this.triggerCancel);
            end
            
            for ii = idxlist
                try
                    [imobj,imInfo] = this.BatchParser.getImage(ii);
                    
                    if isa(this.BatchParser, 'ThroughputMulti')
                         imInfo.PlateID = imInfo.plate;
 
                         %-- TODO: Yinhai experiment
%                          temp = strsplit(imInfo.PlateID, '_');
%                          imInfo.PlateID = str2double(temp{end});
                         
                         imInfo = rmfield(imInfo, 'plate');
                    else
                        %--- Quick fix, only works for this parser.
                        imInfo.PlateID = this.BatchParser.ParserObj.PlateName;

                         %-- TODO: Yinhai experiment
%                         temp = strsplit(imInfo.PlateID, '_');
%                         imInfo.PlateID = str2double(temp{end});
                    end;
                    
                    imInfo.RowID = imInfo.Well(1);
% %                     [imInfo.RowID, imInfo.ColID] = wellstr2rowcol(imInfo.Well);
                    [~, imInfo.ColID] = wellstr2rowcol(imInfo.Well);                       
                        
                    extradata = [];

                    if ~isempty(this.SegMngrObj)
                        if isa(this.SegMngrObj,'SegmentationManager')
                            [labdata,imdata,extradata] = this.SegMngrObj.processImage(imobj);
                        elseif isa(this.SegMngrObj,'AZSeg')
                            % direct segmentation class supplied
                            imdata = imobj{1}.rawdata();
                            [labdata,imdata,extradata] = this.SegMngrObj.process(imdata);
                        else
                            imdata = imobj{1}.rawdata();
                            [labdata,imdata,extradata] = this.SegMngrObj(imdata);
                        end

                        if ~isempty(this.MeasMngrObj)
                            if isa(this.MeasMngrObj,'MeasurementManager')
                                
                                stats = this.MeasMngrObj.measure(labdata,imdata,imInfo);
                            elseif isa(this.MeasMngrObj,'AZMeasure')
                                stats = this.MeasMngrObj.measure(labdata,imdata);
                                stats = mergefields(repmat(imInfo,size(stats)),stats);
                            else
                                stats = this.MeasMngrObj(labdata,imdata);
                                stats = mergefields(repmat(imInfo,size(stats)),stats);
                            end
                        end

                        if ~isempty(this.ExportMngrObj)
                            if ~isa(this.ExportMngrObj,'function_handle')
                                this.ExportMngrObj.export(stats,labdata,imdata,imInfo);
                            else
                                % at the moment the individual export classes need the
                                % filename taken care of for them, so leave this as it
                                % is here.
                                this.ExportMngrObj(stats,labdata,imdata,imInfo);
                            end
                        end
                    end

                    % at the end, run any custom functions which have also been
                    % supplied.  At the moment, this is how the QC images will
                    % be saved, until a proper class is made
                    if ~isempty(this.CustomFunctions)
                        for jj = 1:numel(this.CustomFunctions)
                            this.CustomFunctions{jj}(stats,labdata,imdata,extradata);
                        end
                    end
                catch ME
                    % want to print this to a log file, in such a way that
                    % we can re run only those that didn't work the first
                    % time
                    %
                    % For now, just display a warning
                    warning('IA:BatchError','Error in image number %d, skipping',ii)
                    
                    disp(getReport(ME,'extended'))
                end
                
                progressBarAPI('increment')
                
                if this.CancelBatch
                    break
                end
                
            end
            
            progressBarAPI('finish')
            if ~isempty(cancelhandle)
                delete(templstn)
            end
        end
        
        
        function triggerCancel(this,src,evt)
            this.CancelBatch = true;
            % update the message to show that it has worked
            
            progressBarAPI('message','Cancelling at end of current image')
        end
        
        
        function runSingleImage(this,idx)
            [imobj,imInfo] = this.BatchParser.getImage(idx);
                
            extradata = [];

            if ~isempty(this.SegMngrObj)
                if isa(this.SegMngrObj,'SegmentationManager')
                    [labdata,imdata,extradata] = this.SegMngrObj.processImage(imobj);
                elseif isa(this.SegMngrObj,'AZSeg')
                    % direct segmentation class supplied
                    imdata = imobj{1}.rawdata();
                    [labdata,imdata,extradata] = this.SegMngrObj.process(imdata);
                else
                    imdata = imobj{1}.rawdata();
                    [labdata,imdata,extradata] = this.SegMngrObj(imdata);
                end

                if ~isempty(this.MeasMngrObj)
                    if isa(this.MeasMngrObj,'MeasurementManager')
                        stats = this.MeasMngrObj.measure(labdata,imdata,imInfo);
                    elseif isa(this.MeasMngrObj,'AZMeasure')
                        stats = this.MeasMngrObj.measure(labdata,imdata);
                        stats = mergefields(repmat(imInfo,size(stats)),stats);
                    else
                        stats = this.MeasMngrObj(labdata,imdata);
                        stats = mergefields(repmat(imInfo,size(stats)),stats);
                    end
                end

                if ~isempty(this.ExportMngrObj)
                    if ~isa(this.ExportMngrObj,'function_handle')
                        this.ExportMngrObj.export(stats,labdata,imdata,imInfo);
                    else
                        % at the moment the individual export classes need the
                        % filename taken care of for them, so leave this as it
                        % is here.
                        this.ExportMngrObj(stats,labdata,imdata,imInfo);
                    end
                end
            end

            % at the end, run any custom functions which have also been
            % supplied.  At the moment, this is how the QC images will
            % be saved, until a proper class is made
            if ~isempty(this.CustomFunctions)
                for jj = 1:numel(this.CustomFunctions)
                    this.CustomFunctions{jj}(stats,labdata,imdata,extradata);
                end
            end
        end
        
        
        function parRunBatch(this,idxlist)
            % when running in parallel, it's best to ensure that every
            % image exports to a different file, and then have a function
            % for bringing them all together at the end
            % do the segmentation, measurement and export for every image
            
            % another option for running the batch analysis would be to
            % have the batch parser define the image list in two
            % dimensions, one done with a regular for loop (with progress
            % bar), and inside that a parfor loop that does things in
            % parallel.  For this to make sense the parfor dimension (eg
            % field of view) would need to be at least as big as the number
            % of workers.
            % Also, it would require an additional interface to the
            % batchparser (or a more confusing single interface..)
            if nargin<2 || isempty(idxlist)
                idxlist = 1:this.BatchParser.getNumImages;
            end
            idxlist = idxlist(:)';
            
            
            bp = this.BatchParser;
            ss = this.SegMngrObj;
            mm = this.MeasMngrObj;
            ee = this.ExportMngrObj;
            custfunc = this.CustomFunctions;
            
            progressBarAPI('forcefinish')
%             progressBarAPI('setstyle',@SpinProgMsgBar)
            progressBarAPI('setstyle',@()[])
            progressBarAPI('init','Running parallel batch',1)
            progressBarAPI('lockcaller');
            
            parfor ii = 1:numel(idxlist)
                try
                    [imobj,imInfo] = bp.getImage(idxlist(ii));
                    
                    if isa(bp, 'ThroughputMulti')
                         imInfo.PlateID = imInfo.plate;
                        
                         imInfo = rmfield(imInfo, 'plate');
                    else
                        %--- Quick fix, only works for this parser.
                        imInfo.PlateID = bp.ParserObj.PlateName;
                    end;
                    
                    imInfo.RowID = imInfo.Well(1);
% %                     [imInfo.RowID, imInfo.ColID] = wellstr2rowcol(imInfo.Well);
                    [~, imInfo.ColID] = wellstr2rowcol(imInfo.Well);                       
                        
                    
                    imdata = [];
                    labdata = [];
                    extradata = [];
                    stats = [];
                    
    %                 stats = [];
                    if ~isempty(ss)
                        if isa(ss,'SegmentationManager')
                            [labdata,imdata,extradata] = ss.processImage(imobj);
                        elseif isa(ss,'AZSeg')
                            % direct segmentation class supplied
                            imdata = imobj{1}.rawdata();
                            [labdata,imdata,extradata] = ss.process(imdata);
                        else
                            imdata = imobj{1}.rawdata();
                            [labdata,imdata,extradata] = ss(imdata);
                        end

                        if ~isempty(mm)
                            if isa(mm,'MeasurementManager')
                                stats = mm.measure(labdata,imdata,imInfo);
                            elseif isa(mm,'AZMeasure')
                                stats = mm.measure(labdata,imdata);
                                stats = mergefields(repmat(imInfo,size(stats)),stats);
                            else
                                stats = mm(labdata,imdata);
                                stats = mergefields(repmat(imInfo,size(stats)),stats);
                            end
                        end

                        if ~isempty(ee)
                            if ~isa(ee,'function_handle')
                                ee.export(stats,labdata,imdata,imInfo);
                            else
                                % at the moment the individual export classes need the
                                % filename taken care of for them, so leave this as it
                                % is here.
                                ee(stats,labdata,imdata,imInfo);
                            end
                        end
                    end

                    % at the end, run any custom functions which have also been
                    % supplied.
                    if ~isempty(custfunc)
                        for jj = 1:numel(custfunc)
                            custfunc{jj}(stats,labdata,imdata);
                        end
                    end
                catch ME
                    fprintf('Error in image number %d\n',idxlist(ii));
                    showErrorMsg(ME)
                end
            end
            
            % only update once it's finished
            progressBarAPI('increment')
            progressBarAPI('finish')
            
            
        end
        
        function L = getLabelData(this,varargin)
            % first attempt at integrating the QC viewing, by loading the
            % appropriate label matrices.
            
            % The combination into an annotated image shouldn't really be
            % done here, this should just return the label arrays
            
            if numel(varargin)==1
                CP = varargin{1};
            else
                CP = this.BatchParser.ParserObj.getValuesFromInputs(varargin{:});
            end
            
            if isa(CP,'ChoicesGUI') || ~isstruct(CP)
                info = this.BatchParser.ParserObj.getSelectedInfo(CP);
            else
                info = CP;
            end
            
            ind = find(cellfun(@(x)isa(x,'MatLabelAZExport'),this.ExportMngrObj.ExportArray));
            
            outfile = this.ExportMngrObj.NameFunc{ind}(info); % at the moment this assumes that the first export method is the label matrices
            
            L = load(fullfile(this.ExportMngrObj.OutputFolder,outfile));
            L = L.labelData;
% %             imobj = bp.ParserObj.getSelectedImage(CP);
% %             
% %             % haven't completed the 3DnC label array
% %             % or indeed the combined point and region label class
% %             comboImObj = cAnnotatedImage(imobj{1},cLabel2DnC(L.labelData));
        end
        
        function stats = getStatsData(this,varargin)
            % first attempt at integrating the QC viewing, by loading the
            % appropriate label matrices.
            
            % The combination into an annotated image shouldn't really be
            % done here, this should just return the label arrays
            if nargin==1
                CP = varargin{1};
            else
                CP = this.BatchParser.ParserObj.getValuesFromInputs(varargin{:});
            end
            
            if isa(CP,'ChoicesGUI') || ~isstruct(CP)
                info = this.BatchParser.ParserObj.getSelectedInfo(CP);
            else
                info = CP;
            end
            
            ind = find(cellfun(@(x)isa(x,'MatStatsAZExport'),this.ExportMngrObj.ExportArray));
            
            outfile = this.ExportMngrObj.NameFunc{ind}(info); % at the moment this assumes that the first export method is the label matrices
            
            S = load(fullfile(this.ExportMngrObj.OutputFolder,outfile));
            
            % this might break down for later workflows, need to account
            % for this!
            fnames = fieldnames(S);
            if numel(fnames)==1
                stats = S.(fnames{1});
            else
                % at the moment, it's most likely to be scstats and
                % fieldstats, so just do that for now
                for kk = numel(fnames):-1:1
                    stats{kk,1} = S.(fnames{kk});
                end
            end
% %             imobj = bp.ParserObj.getSelectedImage(CP);
% %             
% %             % haven't completed the 3DnC label array
% %             % or indeed the combined point and region label class
% %             comboImObj = cAnnotatedImage(imobj{1},cLabel2DnC(L.labelData));
        end
        
        function saveSettings(this,saveName)
            % currently, the only settings that get saved are the
            % segmentation settings
            
            if nargin<2 || isempty(saveName)
                saveName = 'IASettings.json';
            end
            % check if there's a dot in the filename, and if not, add the
            % json extension
            if isempty(strfind(saveName,'.'))
                saveName = [saveName,'.json'];
            end
            % save into the output folder, maybe add a settings folder as
            % well?
            outfile = fullfile(this.ExportMngrObj.OutputFolder,'Settings',saveName);
            
            this.SegMngrObj.saveSettings(outfile);
            
        end
        
        function loadSettings(this,fileName)
            if nargin<2 || isempty(fileName)
                fileName = fullfile(this.ExportMngrObj.OutputFolder,'Settings','IASettings.json');
            end
            if isempty(strfind(fileName,'.'))
                fileName = [fileName,'.json'];
            end
            
            this.SegMngrObj.loadSettings(fileName);
        end
        
        function setOutputFolder(this,outputfolder)
            this.ExportMngrObj.setOutputFolder(syspath(outputfolder));
        end
        
        function idxs = findMissingResults(this)
            % look at the exported label mat files to find out if there are
            % any results missing, which will need to be rerun or examined
            
            idxs = [];
            % also want to check here that the first export method is the
            % mat label file that we're after (actually it doesn't really
            % matter which export is used, as long as it's one that has a
            % unique file for each image)
            
            for ii = 1:this.BatchParser.getNumImages
                tempinfo = this.BatchParser.getImageInfo(ii);
                outfile = this.ExportMngrObj.getOutputFile('label',tempinfo);
                
                % does the output file exist?
                if ~exist(outfile,'file')
                    idxs = [idxs;ii];
                end
            end
        end
        
        function [stats,badInds] = loadAllResults(this,statsType,mergeDifferent,loadnames)
            if nargin<4
                loadnames = [];
            end
            if nargin<3 || isempty(mergeDifferent)
                mergeDifferent = false;
            end
            
            if nargin<2 || isempty(statsType)
                statsType = 'both';
            end
            
            switch lower(statsType)
                case {'sc','singlecell'}
                    fname = 'scStats';
                case 'field'
                    fname = 'fieldStats';
                case 'both'
                    fname = {'scStats';'fieldStats'};
                otherwise
                    fname = statsType;
            end
            
            if ~iscell(fname)
                fname = {fname};
            end
            
            stats = cell(numel(fname),1);
            badInds = [];
            for ii = 1:this.BatchParser.getNumImages
                try
                    outfile = this.ExportMngrObj.getOutputFile('stats',this.BatchParser.getImageInfo(ii));
                    if ~exist(outfile,'file')
                        error('Missing file')
                    end
                    S = load(outfile);
                    
                    % one possibility is to string together everything we
                    % find.
                    
                    for jj = 1:numel(fname)
                        tstats = S.(fname{jj});
% %                         temp = num2cell(1:numel(tstats));
% %                         [tstats.CellIndex] = temp{:}; % would this be better referred to as object index?
                        
                        if ~isempty(loadnames)
                            % only keep fields which have been explicitly
                            % asked for
                            allnames = fieldnames(tstats);
                            keepind = cellfun(@(x)any(strcmpi(x,loadnames)),allnames);
                            
                            tstats = rmfield(tstats,allnames(~keepind));
                            
                        end
                        
                        if mergeDifferent
                            % check the field names and make sure they match
                            if ~isempty(stats) & ~isempty(tstats)
                                if ~isempty(stats{jj})
                                    tstats = addMissingFields(tstats,fieldnames(stats{jj}),NaN);
                                
                                    if ~isempty(tstats)
                                        stats{jj} = addMissingFields(stats{jj},fieldnames(tstats),NaN);
                                    end
                                end
                            end

                        end

                        stats{jj} = [stats{jj};tstats(:)];
                    end
                catch ME
                    badInds = [badInds;ii];
                end
                
            end
        end
        
        function deleteSelectedResults(this,remIdx)
            IAHelp();
        end
        
        function setPixelSize(this,pixsize)
            if nargin>1 && ~isempty(pixsize) && isa(this.MeasMngrObj,'MeasurementManager')
                this.MeasMngrObj.setPixelSize(pixsize);
            end
        end
        
        function saveProject(this,fileName)
            % rather than saving the file, would it be easier to save the
            % elements separately and then reload them?
            
            % Just directly save for now, since the class saver might solve
            % this problem
            WorkFlowObject = this;
            
            % remove any images and label data from the Segmentation part
            WorkFlowObject.SegMngrObj.ImageData = {};
            WorkFlowObject.SegMngrObj.LabelData = {};
            
            save(fileName,'WorkFlowObject');
        end
        
        function loadProject(this,fileName)
            % this needs to be able to add a workflow from scratch
            
            S = load(fileName);
            
            fnames = fieldnames(S);
            ind = find(cellfun(@(x)isa(S.(x),'HCWorkFlow'),fnames),1,'first');
            
            if ~isempty(ind)
                tempWorkFlow = S.(fnames{ind});
                
                % need to transfer things over, rather than directly
                % replacing the whole object
                propnames = fieldnames(struct(tempWorkFlow));
                
                for ii = 1:numel(propnames)
                    this.(propnames{ii}) = tempWorkFlow.(propnames{ii});
                end
            else
                warning('File Not Found')
            end
        end
        
        function imreg = regionQC(this,idxvals)
            % return a cell array of QC images to be manually examined
            
            % not sure if this belongs inside the workflow class, but it's
            % a reasonable place to start
            
            if nargin<2 || isempty(idxvals)
                idxvals = 1:this.BatchParser.getNumImages;
            end
            
            cols = uint8(255*[1,1,1;1,1,0;0,1,1;1,0,1]);
            
            imreg = cell(numel(idxvals),1);
            for ii = 1:numel(idxvals)
                [imObj,info] = this.BatchParser.getImage(ii);
                L = this.getLabelData(info);
                if ~iscell(L)
                    L = {L};
                end
                
                rgb = uint8(255*imobj2rgb(imObj));
                L = cellfun(@(x)max(x,[],3),L,'uni',false);
                
                for jj = 1:numel(L)
                    bordmask = L{jj}>0;
                    bordmask = bordmask & ~imerode(bordmask,[0,1,0;1,1,1;0,1,0]);
                    rgb = imoverlay(rgb,bordmask,cols(mod(jj-1,size(cols,1))+1,:),ceil(1/this.QCResolution));
                end
                
                imreg{ii} = imresize(rgb,this.QCResolution); % adjust the method as necessary
            end
        end
        
    end
    
    methods (Static)
        % Static methods of the WorkFlow class could be used to load preset
        % workflows, for example the ViewRNA below
        function flowObj = buildFromFile(fileName)
            
            flowObj = HCWorkFlow();
            
            S = load(fileName);
            
            fnames = fieldnames(S);
            ind = find(cellfun(@(x)isa(S.(x),'HCWorkFlow'),fnames),1,'first');
            
            if ~isempty(ind)
                tempWorkFlow = S.(fnames{ind});
                
                % need to transfer things over, rather than directly
                % replacing the whole object
                propnames = fieldnames(struct(tempWorkFlow));
                
                for ii = 1:numel(propnames)
                    flowObj.(propnames{ii}) = tempWorkFlow.(propnames{ii});
                end
            else
                warning('File Not Found')
            end
        end
        
        function flowObj = viewRNA(nucchan,cytochan,spotchans,outputfolder,parserObj)
            
            if nargin<5
                % allow the parser to be added later
                parserObj = [];
            end
            
            % remember to add the input processing settings!
            ss = SegmentationManager();
            
            isettings{nucchan} = 'max';
            isettings{cytochan} = 'max';
            isettings(spotchans) = repmat({'full'},[1,numel(spotchans)]);
            
            ss.supplyInputSettings(isettings);
            ss.addProcess(DoGNucAZSeg(50,0.005),nucchan);
            ss.addProcess(CytoFibreAZSeg(2,0.1),cytochan,1);
            for ii = 1:numel(spotchans)
                ss.addProcess(SpotDetect3DNoLabelAZSeg(1.5,0.8,10),spotchans(ii));
            end
            
            
            mm = MeasurementManager;
            mm.addMeasurement(ShapeStatsAZMeasure('Nuc'),1,[]);
            mm.addMeasurement(ShapeStatsAZMeasure('Cell'),2,[]);
            for ii = 1:numel(spotchans)
                chlabel = sprintf('Ch%d',spotchans(ii));
                mm.addMeasurement(SpotStatsAZMeasure(chlabel,3),[2,spotchans(ii)],[]);
            end
            
            if nargin<4
                outputfolder = cd;
            end
            ee = ExportManager(outputfolder);
            ee.addExporter(MatLabelAZExport(),@yokoLabelFile);
            ee.addExporter(MatStatsAZExport(),@yokoStatsFile);
            
            % remove the spot percentile from the spreadsheet export
            for ii = 1:numel(spotchans)
                settings.exclude{ii} = sprintf('Ch%dSpotPercentile',spotchans(ii));
            end
            
            % think a single export file will cause problems for parallel
            % implementation
            ee.addExporter(SemicolonSeparatedAZExport(settings),...
                @(x)sprintf('stats/results_w%s_f%d.dat',x.Well,x.Field));
            
            
            flowObj = HCWorkFlow(ss,mm,ee,parserObj,'ViewRNA');
        end
        
        function flowObj = H358ViewRNA(nucchan,cytochan,spotchans,outputfolder,parserObj)
            
            if nargin<5
                % allow the parser to be added later
                parserObj = [];
            end
            
            % remember to add the input processing settings!
            ss = SegmentationManager();
            
            isettings{nucchan} = 'max';
            isettings{cytochan} = 'mean';
            isettings(spotchans) = repmat({'full'},[1,numel(spotchans)]);
            
            ss.supplyInputSettings(isettings);
            ss.addProcess(DenseNucAZSeg(50,0.005),nucchan);
            ss.addProcess(DenseCellMaskAZSeg(2,0.1),cytochan,1);
            for ii = 1:numel(spotchans)
                ss.addProcess(SpotDetect3DNoLabelAZSeg(1.5,0.8,10),spotchans(ii));
            end
            
            mm = MeasurementManager;
            mm.addMeasurement(ShapeStatsAZMeasure('Nuc'),1,[]);
            mm.addMeasurement(ShapeStatsAZMeasure('Cell'),2,[]);
            for ii = 1:numel(spotchans)
                chlabel = sprintf('Ch%d',spotchans(ii));
                mm.addMeasurement(SpotStatsAZMeasure(chlabel,3),[2,ii+2],[]);
            end
            
            if nargin<4
                outputfolder = [];
            end
            ee = ExportManager(outputfolder);
            ee.addExporter(MatLabelAZExport(),@yokoLabelFile);
            ee.addExporter(MatStatsAZExport(),@yokoStatsFile);
            
            % remove the spot percentile from the spreadsheet export
            for ii = 1:numel(spotchans)
                settings.exclude{ii} = sprintf('Ch%dSpotPercentile',spotchans(ii));
            end
            
            
            ee.addExporter(SemicolonSeparatedAZExport(settings),@(x)['stats/results.dat'])
            
            flowObj = HCWorkFlow(ss,mm,ee,parserObj,'ViewRNA');
        end
        
        
        function flowObj = gelShrinkage(outputfolder,parserObj)
            if nargin<2
                parserObj = [];
            end
            if ischar(parserObj)
                parserObj = ParserTrueColour(parserObj,'*.tif',3);
            end
            
% %             ss = SegmentationManager();
% %             ss.supplyInputSettings({'','',''})
% %             ss.addProcess(GelShrinkageAZSeg(),[1,2,3])

            ss = GelShrinkageAZSeg();
            
            mm = MeasurementManager;
            mm.addMeasurement(ShapeStatsAZMeasure('Gel'),2,[]);
            
            if nargin<1
                outputfolder = [];
            end
            ee = ExportManager(outputfolder);
            ee.addExporter(MatLabelAZExport(),@(x)sprintf('labels/label_%d.mat',x.Index));
            ee.addExporter(QCOverlayAZExport(),@(x)sprintf('QCImages/QC%s.png',x.Label))
            ee.addExporter(SemicolonSeparatedAZExport(),@(x)['stats/output_', outputfolder '.dat'])
            flowObj = HCWorkFlow(ss,mm,ee,parserObj,'Gel Area');
            
        end
        
        function flowObj = gsk3bt(outputfolder,parserObj)
            if nargin<2
                parserObj = [];
            end
            if ischar(parserObj)
                parserObj = ParserYokogawa(parserObj);
            end
            
            ss = SegmentationManager();
            
            isettings = {'max','max','max','max'}; % they should already be 2D anyway..
            
            nucchan = 1;
            cytochan = 4;
            
            ss.supplyInputSettings(isettings);
            ss.addProcess(LowMagNucAZSeg(10,0.12,0.3),nucchan);
            ss.addProcess(ClusterGradMaskAZSeg(0.2),cytochan,1);
            
            mm = MeasurementManager;
            mm.addMeasurement(ShapeStatsAZMeasure('Nuc'),1,[]);
            mm.addMeasurement(BasicIntensityAZMeasure('Cyto'),2,1:4);
            mm.addMeasurement(CentroidIntensityAZMeasure('Point',[0,1,0;1,1,1;0,1,0]),...
                1,1:4);
            
            if nargin<1
                outputfolder = [];
            end
            ee = ExportManager(outputfolder);
            ee.addExporter(MatLabelAZExport(),@(x)sprintf('labels/label_w%s_f%d.mat',x.Well,x.Field));
            ee.addExporter(MatStatsAZExport(),@(x)sprintf('stats/stats_w%s_f%d.mat',x.Well,x.Field));
            flowObj = HCWorkFlow(ss,mm,ee,parserObj);
            
        end
    end
end
