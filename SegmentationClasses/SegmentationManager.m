classdef SegmentationManager < handle
    % first attempt at stand-alone segmentation manager
    % 
    % - takes a predefined set of images
    % - define which channels to be used for each part
    % - define any pre-processing to be applied for each channel, eg
    %   flattening a 3D image (but not limited to this).  It is in this
    %   step that perhaps any unneeded channels can be flagged so that they
    %   don't waste time being read from file.
    % - The processing operations are all a common type at the moment:
    %   input image channels and optionally label channels, and get label
    %   channel(s) out - but an additional operation could be new image
    %   channels out, or mixed labels and images out - this needs to be
    %   reflected in the AZSeg interface when required
    
    % Alongside this implementation, the LabelClass interface needs to be
    % updated so that the region-based label is a sub-class, and
    % point-based labels are also possible.
    
    properties (SetAccess = ?HCWorkFlow)
        InputProcessing
        ImageData
        LabelData = {};
        
        LabelStages = [] % records the current status of the output labels
                    % 1 - not segmented - get by running segmentation
                    % 2 - in memory - direct access
                    % 3 - saved to file - get by loading the file
                    
                    % note that QC images should be saved separately from
                    % the labels
                   
        ProcArray = {} % cell array of the processing objects (segmentation steps)
        ProcInputChannels = {} % cell array of the image channels that go into each segmentation
        ProcInputLabels = {} % cell array of the label channels that go into each segmentation
        % need to check that LabelSource and ProcInputLabels are
        % consistent
        
        LabelSource = [] % index of the processing array, telling us where each label comes from
        ProcOutputLabels = {};
        
        ProcDisplayChoice = {};
        
        NativeColour
        PixelSize
    end
    methods
        function this = SegmentationManager()
            % try out the no-arguments in the constructor style
            % everything is added through method calls
            
        end
        
        function supplyInputSettings(this,iSettings)
            % get the input settings - this is what should be done with
            % each of the input channels, and needs to be in place before
            % the input images are passed
            
            % JSON seems like a good format for storing all the settings,
            % but for now, a simple cell array will do..
            
            this.InputProcessing = iSettings;
        end
        
        function supplyInputImages(this,imgArray,iSettings)
            % load the image data from each of the image objects supplied
            
            % if necessary, we can clear the ImData from the objects at the
            % end to save memory, since we'll have everything we need
            
            if nargin>2 && ~isempty(iSettings)
                this.supplyInputSettings(iSettings);
            end
            
            if isempty(imgArray)
                return
            end
            
            if ~iscell(imgArray)
                imgArray = {imgArray};
            end
            
            % image data will be stored as a cell array of cell arrays
            
            % get the colour information from the first image and
            % assume it is the same for the rest..
            this.NativeColour = imgArray{1}.NativeColour;
            this.PixelSize = imgArray{1}.PixelSize;
            
            this.ImageData = cell(numel(imgArray),1);
            for ii = 1:numel(imgArray)
                this.ImageData{ii} = this.prepareImage(imgArray{ii});
            end
            
            if ~isempty(this.ProcArray)
                % need to reinitialize any labels for new input images
                
                % initialize the labels - this part needs to be done only
                % after the images have been added
                try
                for jj = 1:numel(this.ProcOutputLabels)
                    newLabelIndices = this.ProcOutputLabels{jj};
                    this.LabelStages(newLabelIndices) = 1; % stage 1 = not segmented yet
                    for ii = 1:numel(this.ImageData)
                        this.LabelData{ii}(newLabelIndices) = {[]};
                    end
                end
                catch me
                    rethrow(me)
                end
                    
% %                 error('Can''t add images after segmentation methods yet')
            end
        end
        
        function imdata = prepareImage(this,imobj)
            if iscell(imobj)
                imobj = imobj{1};
            end
            
            
            % rather than iterating over the number of specified settings,
            % we should iterate over the number of channels present?
            
            chanProcess = repmat({'full'},[1,imobj.NumChannel]);
            chanProcess(1:numel(this.InputProcessing)) = this.InputProcessing;
                
            imdata = cell(numel(chanProcess),1);
            
            for jj = 1:numel(chanProcess)
                if isa(chanProcess{jj},'function_handle')
                    temp = imobj.rawdata(jj);
                    if ~iscell(temp)
                        temp = {temp};
                    end
                    
                    imdata{jj} = chanProcess{jj}(temp);
                else
                    try
                    switch chanProcess{jj}
                        case 'ignore'
                            imdata{jj} = [];
                        case 'max'
                            temp = imobj.rawdata(jj);
                            if ~iscell(temp)
                                temp = {temp};
                            end
                    
                            imdata{jj} = max(temp{1},[],3);
                        case 'mean'
                            temp = imobj.rawdata(jj);
                            if ~iscell(temp)
                                temp = {temp};
                            end
                    
                            imdata{jj} = uint16(mean(temp{1},3)); % should maybe cast back to uint16 to save memory?
                        otherwise
                            temp = imobj.rawdata(jj);
                            if ~iscell(temp)
                                temp = {temp};
                            end
                            imdata{jj} = temp{1}; % ideally this won't make a copy..

                    end
                    catch me
                        rethrow(me)
                    end
                end
            end
        end
        
        function addProcess(this,procObj,inputChanInfo,inputLabInfo,displayChoice)
            % this is generically called 'process', but for now it really
            % means segmentation
            
            % for now we can assume that processes are only added, never
            % removed
            
            % the input channels and labels could be added afterwards, this
            % might be a better arrangement..
            
            numLabOutputs = procObj.getNumOutputs(); % these are always labels at the moment
            
            prevNumLabels = numel(this.LabelStages);
            
            newLabelIndices = prevNumLabels + (1:numLabOutputs);
            
            procIndex = numel(this.ProcArray)+1;
            
% %             if all(isfinite(inputChanInfo)) && ~isempty(procObj.getNumInputs()) && numel(inputChanInfo)~=procObj.getNumInputs()
% %                 warning('Input channels must match')
% %             end
            
            if nargin<4
                inputLabInfo = [];
            end
            
            if procObj.getNumLabelInputs>0 && isempty(inputLabInfo)
                error('Need to specify label inputs')
            end
            
            if any(inputLabInfo>prevNumLabels)
                error('Label input must be pre-existing')
            end
            
            this.ProcArray{procIndex} = procObj;
            this.LabelSource(newLabelIndices) = procIndex;
            
            % this is redundant with LabelSource, but see which is most
            % useful
            this.ProcOutputLabels{procIndex} = newLabelIndices;
            
            this.ProcInputChannels{procIndex} = inputChanInfo;
            this.ProcInputLabels{procIndex} = inputLabInfo;
            
            % initialize the labels - this part needs to be done only
            % after the images have been added
            % CHECK THAT THIS DOENS'T CAUSE PROBLEMS WITH THE ORDER OF
            % IMAGE AND PROCESS ADDING
            this.LabelStages(newLabelIndices) = 1;
            
            for ii = 1:numel(this.ImageData)
                this.LabelData{ii}(newLabelIndices) = {[]};
            end
            
            if nargin>4 && ~isempty(displayChoice)
                this.ProcDisplayChoice{procIndex} = displayChoice;
            else
                this.ProcDisplayChoice{procIndex} = [];
            end
        end
        
        function runStep(this,step)
            % prototype method for running the chosen step, and all
            % required preceding analysis to enable the step to be run
            
            
            reqLabels = this.ProcInputLabels{step};
            reqChan = this.ProcInputChannels{step};
            outputLabels = this.ProcOutputLabels{step};
            
            for ii = 1:numel(reqLabels)
                this.getLabelData(reqLabels(ii));
            end
            
            % having got the required previous steps, now run the current
            % step on each image
            
            tempproc = this.ProcArray{step};
            tempim = this.ImageData;
            templab = this.LabelData;
            
            
%             parfor ii = 1:numel(this.ImageData)
            for ii = 1:numel(this.ImageData) % keep this to be able to debug
                if ~isfinite(reqChan)
                    currChan = 1:numel(tempim{ii});
                else
                    currChan = reqChan;
                end
                
                
                tempL = process(tempproc,tempim{ii}(currChan),templab{ii}(reqLabels));
                
                if ~iscell(tempL)
                    tempL = {tempL};
                end
                
                templab{ii}(outputLabels) = tempL(:); % maybe needs to be tempL(:)
                
            end
            
            this.LabelData = templab;
            if ~isempty(this.LabelStages)
                this.LabelStages(outputLabels) = 2;
            end
            
        end
        
        function tuneStep(this,step)
            
            reqLabels = this.ProcInputLabels{step};
            reqChan = this.ProcInputChannels{step};
            outputLabels = this.ProcOutputLabels{step};
            
            for ii = 1:numel(reqLabels)
                this.getLabelData(reqLabels(ii));
            end
            
            % having got the required previous steps, now run the current
            % step on each image
            
            tempproc = this.ProcArray{step};
            
%             tempim = this.ImageData;
            tempim = cellfun(@(x)x(reqChan),this.ImageData,'uni',false);
            
            templab = cellfun(@(x)x(reqLabels),this.LabelData,'uni',false);
            
            % any parallelization needs to be done inside the tuner object
            
            tunObj = InteractiveTuner(tempproc,tempim,templab);
            
            outL = tunObj.runTuner();
            
            % then distribute the newly calculated labels
            for ii = 1:numel(this.ImageData)
                if ~iscell(outL{ii})
                    this.LabelData{ii}(outputLabels) = {outL{ii}};
                else
                    this.LabelData{ii}(outputLabels) = outL{ii}(:);
                end
            end
            
% %             parfor ii = 1:numel(this.ImageData)
% % %             for ii = 1:numel(this.ImageData) % keep this to be able to debug
% %                 tempL = process(tempproc,tempim{ii}(reqChan),templab{ii}(reqLabels));
% %                 
% %                 if ~iscell(tempL)
% %                     tempL = {tempL};
% %                 end
% %                 
% %                 templab{ii}(outputLabels) = tempL(:); % maybe needs to be tempL(:)
% %                 
% %             end
% %             
% %             this.LabelData = templab; 

            this.LabelStages(outputLabels) = 2;
            
        end
        
        function getLabelData(this,reqLabels)
            % make sure that the required labels have been brought
            % into memory for subsequent use.
            
            for ii = 1:numel(reqLabels)
                switch this.LabelStages(reqLabels(ii))
                    case 1
                        % not been segmented yet, do this!
                        % try using runStep to bring it into memory
                        step = this.LabelSource(reqLabels(ii));
                        this.runStep(step);
                    case 2
                        % already in memory, don't need to do anything
                        
                    case 3
                        % has been written to file, load it back up
                        error('Loading not implemented yet, shouldn''t get here')
                    otherwise
                        error('Unknown label status')
                end
            end
        end
        
        function varargout = saveSettings(this,jsonfile)
% %             error('Not implemented yet')
            
            % the settings we want to save are specifically the
            % segmentation settings? Or also the channel info?
            % I think the channel info should be saved as well, because
            % this can easily be overwritten when needed
            
            % try to write the whole thing to one JSON structure, if
            % possible
            
            % the channels are stored in a structure titled "ch", the
            % segmentation settings are stored in "seg"
            % these will get read in as separate cell element structures
            
            ch.ProcInputChannels = this.ProcInputChannels;
            ch.ProcInputLabels = this.ProcInputLabels;
            ch.LabelSource = this.LabelSource;
            ch.ProcOutputLabels = this.ProcOutputLabels;
            
            % rather than getting the JSON from the segmentation, get the
            % structure instead
            for ii = 1:numel(this.ProcArray)
                seg(ii,1) = this.ProcArray{ii}.settingsStruct();
            end
            
            if numel(this.ProcArray)>0
                outstr = [savejson('ch',ch),...
                    savejson('seg',seg)];
            else
                outstr = savejson('ch',ch);
            end
            
            if nargin>1 && ~isempty(jsonfile)
                fid = fopen(jsonfile,'wt+');
                % check that we don't need to create the folder
                if fid<0
                    fol = fileparts(jsonfile);
                    if exist(fol,'dir')~=7
                        mkdir(fol)
                    end
                    fid = fopen(jsonfile,'wt+');
                end
                
                fprintf(fid,outstr);
                fclose(fid);
            end
            
            if nargout>0
                varargout{1} = outstr;
            end

        end
        function loadSettings(this,jsonstr)
%             error('Not implemented yet')
            % Now we need to get the settings back from the JSON structure
            
            if ~strcmpi(jsonstr(1),'{')
                % it's a file name, not a JSON string
                % read the data in
                
                jsonstr = fileread(jsonstr);
                
            end
            S = loadjson(jsonstr);
            
            chind = find(cellfun(@(x)strcmpi(fieldnames(x),'ch'),S));
            
            % input channels should be a cell array
            tempchan = S{chind}.ch.ProcInputChannels;
            if ~iscell(tempchan)
                if size(tempchan,1)==1
                    dim = 1;
                else
                    dim = 2;
                end
                tempchan = num2cell(tempchan,dim);
            end
            
            this.ProcInputChannels = tempchan;
            this.ProcInputLabels = S{chind}.ch.ProcInputLabels;
            this.LabelSource = S{chind}.ch.LabelSource;
            
            % this one needs to be a cell array if it's not already
            templab = S{chind}.ch.ProcOutputLabels;
            if ~iscell(templab)
                if size(templab,1)==1
                    dim = 1;
                else
                    dim = 2;
                end
                templab = num2cell(templab,dim);
            end
            this.ProcOutputLabels = templab;
            % think these might be linked to the ProcArray specifics? So
            % take care if changing one but not the other in the text file
            
            segind = find(cellfun(@(x)strcmpi(fieldnames(x),'seg'),S));
            if ~isempty(segind)
                this.ProcArray = {};
                if iscell(S{segind}.seg)
                    for ii = 1:numel(S{segind}.seg{1})
                        this.ProcArray{ii} = segFactory(S{segind}.seg{1}{ii});
                    end
                else
                    % think this means that there is only one method
                    % BUT it could also mean that there are two algorithms
                    % called with identical properties (eg different colour
                    % nuclei)
                    for ii = 1:numel(S{segind}.seg)
                        this.ProcArray{ii} = segFactory(S{segind}.seg(ii));
                    end
                end
            end
            
        end
        
        
        function saveLabelData(this,labelidx)
            error('Not implemented yet')
        end
        
        function loadLabelData(this,labelidx)
            error('Not implemented yet')
        end
        
        function n = getNumSteps(this)
            n = numel(this.ProcArray);
        end
        
        function flushLabel(this,labelidx)
            % remove the specified label data and flush through the
            % pipeline - this happens if the segmentation settings get
            % changed.
            % actually, the label data doesn't need deleting - just change
            % the labelstages to reflect that it needs to be run again
            
            this.LabelStages(labelidx) = 1;
            
            % then propagate through the whole pipeline
            dependentStages = find(cellfun(@(x) any(x==labelidx), this.ProcInputLabels));
            
            for ii = 1:numel(dependentStages)
                this.flushLabel(dependentStages(ii));
            end
            
        end
        
        function visualizeStep(this,step,displayHandle)
%             IAHelp();
%             return
            
            % Want to only display the labels that are relevant - although
            % is there any harm in displaying all the image channels in the
            % appropriate dimension?
            reqChan = this.ProcInputChannels{step};
            
            for ii = 1:numel(this.ImageData)
                % try to detect the dimensionality
                
                % It might be best to use the dimensionality of the label
                % matrices as a guide to how we want to display the image?
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % this part will probably be replicated in the QC viewer
                % part, so might make sense to have a separate function
                % that can be used for both
                
%                 if any(cellfun(@(x)size(x,3)>1,this.ImageData{ii}(this.ProcInputChannels{step}))
                if any(cellfun(@(x)size(x,3)>1,this.LabelData{ii}(this.ProcOutputLabels{step})))
                    imObj = cImage3DnCNoFile(this.ImageData{ii},this.NativeColour,[],[],'Input image');
                else
                    imObj = cImage2DnC([],[],this.NativeColour,[],[],'Input image',cellfun(@(x)max(x,[],3),this.ImageData{ii},'uni',false));
                end
                % add more details, eg colour channels later
                
                if strcmpi(this.ProcArray{step}.ReturnType,'point')
                    imsiz = size(this.ImageData{ii}{reqChan(1)});
                    labelObj = cPointLabelnC(this.LabelData{ii}(this.ProcOutputLabels{step}),...
                        imsiz);
                else
                    labelObj = cLabel2DnC(this.LabelData{ii}(this.ProcOutputLabels{step}));
                end
                
                anotIm = cAnnotatedImage(imObj,labelObj);
                if ~isempty(this.ProcDisplayChoice{step})
                    anotIm.DefaultDisplay = this.ProcDisplayChoice{step};
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                
                if ~isempty(displayHandle)
                    
                    displayHandle.sendToDisplay(anotIm);
                else
                    anotIm.showImage();
                end
                
            end
        end
        
        function [labdata,imdata,extradata] = processImage(this,imobj)
            % Run the whole workflow on a provided image, without saving
            % anything within the class object
            %
            % This is the step that should be called for a batch run
            
            imdata = this.prepareImage(imobj);
            labdata = cell(max(cellfun(@max,this.ProcOutputLabels)),1);
            
            for step = 1:numel(this.ProcArray)
                reqLabels = this.ProcInputLabels{step};
                reqChan = this.ProcInputChannels{step};
                outputLabels = this.ProcOutputLabels{step};
                
                % this line isn't really up to date with the multiple
                % output options yet, an example will help to get it
                % working properly.
                if this.ProcArray{step}.ReturnsExtraData
                    [tempL,~,extradata] = process(this.ProcArray{step},imdata(reqChan),labdata(reqLabels));
                else
                    tempL = process(this.ProcArray{step},imdata(reqChan),labdata(reqLabels));
                    extradata = [];
                end
                
                % don't do anything with the newimdata yet, but it will be
                % able to add extra channels to the analysis (eg filtered
                % or deconvolved images)
                
                if ~iscell(tempL)
                    tempL = {tempL};
                end
                
                labdata(outputLabels) = tempL(:); % maybe needs to be tempL(:)
                
            end
        end
        
        function setDisplayChoice(this,displayhandle,idx)
            if nargin<3 || isempty(idx)
                idx = 1:numel(this.ProcDisplayChoise);
            end
            if nargin>1 && isa(displayhandle,'function_handle')
                this.ProcDisplayChoice{idx} = displayhandle;
            else
                error('Must supply a function handle')
            end
        end
        
    end
    
    methods (Static)
        % at the moment, currently developed workflows are stored as static
        % methods, so that they can be created and populated with one call
        
        % This might not be the most appropriate way of deploying to
        % multiple projects, but once compiled shouldn't be an issue
        
        % The alternative would be to have separate functions storing the
        % workflow creation, but then they are all separate and makes
        % bringing them together for reuse harder
        
        function [sMgr,sGUI] = gsk3bt(imObj)
            % they will all follow a similar style
            sMgr = SegmentationManager();
            sMgr.supplyInputSettings({'','','',''});
            sMgr.supplyInputImages(imObj);
            sMgr.addProcess(DoGNucAZSeg(),1);
            sMgr.addProcess(PseudoCytoAZSeg(),[],1);
            sGUI = SegManGUI(sMgr);
        end
    end
end