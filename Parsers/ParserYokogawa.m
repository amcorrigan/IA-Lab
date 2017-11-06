classdef ParserYokogawa < ParserHCB
    % parser for the Yokogawa CV7000 images
    % 
    % This is the newer version of CVParserX, taking the hierarchical
    % indexing away from the image loader and putting it inside the GUI
    % class.  What this means is that every property will have to be
    % specified each time an image is read in - this seems like a sensible
    % starting point, rather than trying to keep track of current values..
    % can the image cache still be used in that case?  This is the record
    % of current image
    %


    properties
        
%         ChannelLabels % now moved to ParserHCB
        ChannelLookup
    end

    methods
        
        function this = ParserYokogawa(plateDir)
            % new version parsing the image info from the XML file

            if nargin<1
                error('Please provide location of MeasurementData.mlf file')
            end
            
            % This doesn't work for UNIX
            % Not only that, there's no guarantee that the deepest folder
            % is even the one we're looking for..
            if ispc
                %_________________________________________________
                %  Find the deepest folder and select the wpp file
                this.PlatePath = az_getDeepestChildFolderName(plateDir);
                
                % if this above function is called from a network location,
                % it fails completely, need to check for that here..
                
                if ~isempty(strfind(this.PlatePath,'CMD.EXE'))
                    this.PlatePath = plateDir;
                end
            else
                % for non-Windows, we currently have to select the folder
                % that directly contains the mlf file
                this.PlatePath = plateDir;
            end
            
            %_________________________________________________
            %  In case if user selected the deepest folder.
            if isempty(this.PlatePath)
                this.PlatePath = plateDir;
            end;
            
            % TODO - WHAT HAPPENS WHEN AZ_GETDEEPESTCHILDFOLDERNAME RETURNS
            % MORE THAN ONE FOLDER?
            this.PlatePath = syspath(this.PlatePath);
            
            % store the plate name too for convenience, although perhaps a
            % method would work just as well?
            [~,plName] = fileparts(this.PlatePath);
            this.PlateName = plName;
            
            
            %-- this version is working for Windows environment, not Linux
            if ispc
                cmdArray = sprintf('dir \"%s\\*.mlf\" /b /a-d', this.PlatePath);
                [~, fileName] = dos(cmdArray);
               
                % fix for a warning message that comes up when dir is called
                % from a network location
                newlineInds = strfind(fileName,sprintf('\n'));
                if numel(newlineInds)==1
                    keepRange = [1,newlineInds-1];
                else
                    keepRange = [(newlineInds(end-1)+1),(newlineInds(end)-1)];
                end
                fileName = fileName(keepRange(1):keepRange(2));
            
            else
%                 error('Not currently implemented for non-Windows')
                temp = dir(fullfile(this.PlatePath,'*.mlf'));
                fileName = temp(1).name;
            end

% %             fileName(end) = []; %-- This the carriage return, you cannot see it!!!!
            
            
            if strcmpi(fileName,'File Not Found')
                error('No measurement data file found (.mlf extension)')
            end
            
            if ischar(fileName)
                fid = fopen(fullfile(this.PlatePath, fileName));
                % this is bad practice, fileName is no longer a name, it is
                % a file ID number
            else
                fid = fileName;
            end

            % rather than getting all the properties from the image name,
            % record the image name, but get the properties from the
            % corresponding XML tag
            try
            s = textscan(fid,'%s','Delimiter','\n');
            catch ME
                rethrow(ME)
            end
            s = s{1};

            % will likely need to replace name2props with code in the
            % constructor, since not every line in the file is a valid
            % image
            allnames = regexp(s,'<bts:MeasurementRecord bts:Type="IMG".+>(.+\.tif)</bts:MeasurementRecord>','tokens','once');
            % TODO
            % add a search for ERR as well (additional options)

            % one could use this now to trim down the text array to only
            % the lines we need to check
            imLines = ~cellfun(@isempty,allnames);
            s = s(imLines);
            % remove one layer of cell indexing here as well
            this.ImNames = [allnames{imLines}]';

            
            % by making this a (non-static) class method, the constructor
            % is more general, although don't think this is even needed in
            % this case.
            X = name2props(this,s);
            [M,idx,choices,labels] = existmat(this,X);
            % keep the two above separate for now

            % make sure that the order of the short labels
            % this.addChoices(HierImIndexChoices(labels,choices,[],[],{'w','l','t','s','a','c','z'}',M>0));
            this.ChoiceStruct.Labels = labels;
            this.ChoiceStruct.Choices = choices;
            this.ChoiceStruct.ShortLabels = {'w','l','t','s','a','c','z'}';

            this.ChoiceStruct.ImMap = M;
            this.ImIndex = idx; % Map and Idx are mirrors of each other for going forward and backward - is idx ever needed?

            this.detectImsiz();
            
            this.getChannelColours();
            
            this.setPixelSize();
            this.setZDistance();
            
            this.setPlateDimensions();
            
            % find which combinations of action and channel have images
            acMap = any(joinDimensions(this.ChoiceStruct.ImMap,{5,6}),3);
            [this.ChannelLabels,this.ChannelLookup] = actionChannelFix(acMap);
            
            
        end
      
        function thumbObj = setThumbnail(this)

            colourIndex = any(joinDimensions(this.ChoiceStruct.ImMap, {5, 6}), 3);
            noChannels = nnz(colourIndex);
            
            W = floor(this.ImSize(2)/20);
            H = floor(this.ImSize(1)/20);

            thumbnailImage = zeros([H * this.PlateDimensions(2), W * this.PlateDimensions(1), noChannels], 'uint16');
            
            % add an extra channel containing the annotations
            textImage = zeros(size(thumbnailImage,1),size(thumbnailImage,2),'uint16');
            
            %-- rearranged to be (well, action, channel, z)
            S = joinDimensions(this.ChoiceStruct.ImMap,{1,5,6,7});
            % the function above permutes and reshapes so that the new
            % order is well, action, channel, zslice, then everything else
            % in 1 dimension
            
% %             %-- rearranged to be (well, action, channel, z-slice)
            S = S(:,:,:,:,1);
            % Choose the middle z-slice
            S = ordChoice(S,0.5,4); % 50%, 4th dimension
            
            progressBarAPI('init',nnz(S));
            
            [wellRow, wellCol] = wellstr2rowcol(this.ChoiceStruct.Choices{1});
            
            for i = 1:size(S, 1)
                addtext = false;
                for k = 1:size(S, 3)
                    for j = 1:size(S, 2)

                        if S(i, j, k)==0
                            continue;
                        end
                        
                        
                        imFileName = fullfile(this.PlatePath, this.ImNames{S(i,j,k)});
                        
                        aThumbnail = imresize(imread(imFileName, ...
                                                     'PixelRegion', {[1 10 this.ImSize(1)],[1 10 this.ImSize(2)]}),...
                                                     [H W]);
                                                 
                        thumbnailImage((wellRow(i)-1)*H+1:wellRow(i)*H, (wellCol(i)-1)*W+1:wellCol(i)*W, this.ChannelLookup(j, k)) = aThumbnail;                         
                        
                        progressBarAPI('increment');
                        
                        addtext = true;
                    end;
                end;
                if addtext
                    textRegion = zeros(H,W,'uint16');
                    
                    textRegion = AddTextToImage(textRegion,this.ChoiceStruct.Choices{1}{i},...
                        [1,1],65536,'Arial',ceil(H/4));
                    
                    textImage((wellRow(i)-1)*H+1:wellRow(i)*H, (wellCol(i)-1)*W+1:wellCol(i)*W) = textRegion;                         
                        
                end
            end;
            
            colourChannelIndex = findn(colourIndex);
            revisedColour = this.NativeColours(colourChannelIndex(:, 2));
            
            thumbObj = cImage2DnC([], [],[revisedColour;{[0.99,0.99,0.99]}], [(1:size(thumbnailImage,3))';NaN],...
                [this.PixelSize*20, this.PixelSize*20], 'Plate',...
                [squeeze(num2cell(thumbnailImage,[1, 2]));{textImage}]);            
            
            progressBarAPI('finish');
        end
        
        function getChannelColours(this)
%                      function o_channelColours = getChannelColours(this, i_pathName)
            
            aString = sprintf('%s\\*.mes', this.PlatePath);
            fileName = dir(aString);

            this.NativeColours = repmat({[1 1 1]},[size(this.ChoiceStruct.ImMap,6),1]);
            
            if length(fileName) == 1 && ~isempty(fileName)
        
                fullFileName = sprintf('%s\\%s', this.PlatePath, fileName.name);
                colourStruct = az_parseXML_ChannelColour_mes(fullFileName);
                
                %_________________________________________________
                %   Set the default colour
                for i = 1:length(this.NativeColours)
                    this.NativeColours{colourStruct(i).Ch} = colourStruct(i).Colour;
                end;
            end
        end


        function img2D = get2DObj(this,varargin)
            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            % find the function that recursively converts the cell array to all the permutations

            valArray = expandCellIndices(newVals);
            
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            
            % in the 2D case, we want a cell array of every image requested
            filenames = getFileNames(this,valArray);
            % but some of these can potentially be NaNs, if we've requested
            % multiple actions, etc, so the NaNs have to be weeded out and
            % removed
            
            missingSlices = cellfun(@(x) isscalar(x) && isnan(x),filenames);
            filenames(missingSlices) = [];
            
            valArray = valArray(~missingSlices,:);
            
            imageLabels = this.getImageLabel(valArray,'default');
            
            
            acvals = [valArray(:,aidx),valArray(:,cidx)];
            
            img2D = cell(numel(filenames),1);
            for ii = 1:numel(filenames)
                
% %                 img2D{ii} = cImage2D(filenames{ii},this.NativeColours{valArray(ii,cidx)},...
% %                     valArray(ii,cidx), [this.PixelSize, this.PixelSize],imageLabels{ii});
                currChan = this.ChannelLookup(acvals(ii,1),acvals(ii,2));
                if currChan==0
                    warning('no images for action channel combination')
                    img2D{ii} = [];
                    continue
                end
                img2D{ii} = cImage2D(filenames{ii},this.NativeColours{valArray(ii,cidx)},...
                    currChan, [this.PixelSize, this.PixelSize],imageLabels{ii});
            end
        end

        function img3D = get3DObj(this,varargin)

            newVals = this.getValuesFromInputs(varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            
            
            % find the function that recursively converts the cell array to all the permutations

            % in the 3D case, we want a cell array of every image requested
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            
            valArray = expandCellIndices(newVals(~zidx));
            
            acvals = [valArray(:,aidx),valArray(:,cidx)];
            
            imageLabels = this.getImageLabel(valArray,'default');
            
            img3D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                valWithZ = zeros(numel(newVals{zidx}),numel(newVals));
                valWithZ(:,~zidx) = valArray(ii*ones(size(valWithZ,1),1),:);
                valWithZ(:,zidx) = newVals{zidx};
                
                filenames = this.getFileNames(valWithZ,false);
                
                missingSlices = cellfun(@(x)any(isnan(x)),filenames);
                filenames(missingSlices) = [];
% %                 valWithZ = valWithZ(~missingSlices,:);
                
% %                 img3D{ii} = cImage3D(filenames,this.PlatePath,this.NativeColours{valArray(ii,cidx)},...
% %                     valArray(ii,cidx), [this.PixelSize, this.PixelSize],imageLabels{ii});

                currChan = this.ChannelLookup(acvals(ii,1),acvals(ii,2));
                if currChan==0 || isempty(filenames)
                    warning('no images for action channel combination')
                    img3D{ii} = [];
                    continue;
                end
                img3D{ii} = cImage3D(filenames,this.PlatePath,this.NativeColours{valArray(ii,cidx)},...
                    currChan, [this.PixelSize, this.PixelSize],imageLabels{ii});
                
            end
        end

        function imgC2D = getC2DObj(this,varargin)

            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            % find the function that recursively converts the cell array to all the permutations

            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            
            % in the 2DnC case, separate multiple channels from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~cidx));
            
            imageLabels = this.getImageLabel(valArray,'default');
            
            imgC2D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                valWithC = zeros(numel(newVals{cidx}),numel(newVals));
                valWithC(:,~cidx) = valArray(ii*ones(size(valWithC,1),1),:);
                valWithC(:,cidx) = newVals{cidx};
                
                filenames = this.getFileNames(valWithC,false);
                
                missingSlices = cellfun(@(x)any(isnan(x)),filenames);
                filenames(missingSlices) = [];
                    
                valWithC = valWithC(~missingSlices,:);
                
% %                 chanvals = valWithC(:,cidx);
                acvals = [valWithC(:,aidx),valWithC(:,cidx)];
                chanConstruct = arrayfun(@(x,y)this.ChannelLookup(x,y),acvals(:,1),acvals(:,2));
                
                colourIndex = acvals(:, 2);
                
                imgC2D{ii} = cImage2DnC(filenames,this.PlatePath,this.NativeColours(colourIndex),...
                    chanConstruct, [this.PixelSize, this.PixelSize],imageLabels{ii});
                
            end
        end

        function imgC2D = getAC2DObj(this,varargin)

            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            % find the function that recursively converts the cell array to all the permutations

            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            
            % in the 2DnC case, separate multiple channels from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~cidx & ~aidx));
            
            imageLabels = this.getImageLabel(valArray,'default');
            
            imgC2D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                acVals = expandCellIndices(newVals(cidx | aidx));
                
                valWithAC = zeros(size(acVals,1),numel(newVals));
                valWithAC(:,~cidx & ~aidx) = valArray(ii*ones(size(valWithAC,1),1),:);
                valWithAC(:,cidx | aidx) = acVals;
                
                filenames = this.getFileNames(valWithAC,false);
                % a lot of these will probably be NaN, because action and
                % channel aren't independent
                missingSlices = cellfun(@(x)any(isnan(x)),filenames);
                filenames(missingSlices) = [];
                    
                valWithAC = valWithAC(~missingSlices,:);
                
                acvals = [valWithAC(:,aidx),valWithAC(:,cidx)];
                chanConstruct = arrayfun(@(x,y)this.ChannelLookup(x,y),acvals(:,1),acvals(:,2));
                
                colourIndex = acvals(:, 2);
                
                [~,ix] = sort(colourIndex,'ascend');
                % this is the order that needs applying to everything
                % - filenames
                % - NativeColours
                % - channels
                
                imgC2D{ii} = cImage2DnC(filenames(ix),this.PlatePath,this.NativeColours(colourIndex(ix)),...
                                        chanConstruct(ix), [this.PixelSize, this.PixelSize],imageLabels{ii});
                
            end
        end
        
        function imInfo = getAC2DInfo(this,varargin)
            % get information about the chosen image
            % this info is then fed into a function which will generate the
            % export file name for each export method
            % USE THIS AS A TEMPLATE TO ROLL OUT TO THE OTHER IMAGE TYPES
            % AND THE OTHER IMAGE PARSERS
            
            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            % find the function that recursively converts the cell array to all the permutations
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
%             zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
            % in the 3DnC case, separate multiple channels and z from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~aidx & ~cidx));
            
            tags = this.getImageLabel(valArray,'default');
            imInfo = struct('Label',tags{1},...
                'Well',this.ChoiceStruct.Choices{1}{valArray(:,1)},...
                'TimeLine',this.ChoiceStruct.Choices{2}(valArray(:,2)),...
                'TimePoint',this.ChoiceStruct.Choices{3}(valArray(:,3)),...
                'Field',this.ChoiceStruct.Choices{4}(valArray(:,4)),...
                'ZSlice',this.ChoiceStruct.Choices{7}(valArray(:,5)));
            
            [imInfo.PlateID] = deal(this.PlateName);
        end

        function [imgC3D,info] = getAC3DObj(this,varargin)
            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            
            % check the last three options (action, channel and z) and if
            % they're empty, replace them with Infs
            for ii = 1:7
                if isempty(newVals{ii})
                    newVals{ii} = Inf;
                end
            end
            
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            % Try doing this by replacing Infs with the choices contained
            % in ChoiceStruct - hopefully any missing combinations will be
            % picked up in missingSlices in the loop below (should be fine
            % for hierarchical choices)
            for ii = 1:numel(newVals)
                if any(~isfinite(newVals{ii}))
                    newVals{ii} = this.ChoiceStruct.Choices{ii};
                end
            end
            
            % find the function that recursively converts the cell array to all the permutations
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
            % in the 3DnC case, separate multiple channels and z from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~aidx & ~cidx & ~zidx));
            
            imageLabels = this.getImageLabel(valArray,'default');
            
            imgC3D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                acVals = expandCellIndices(newVals(cidx | aidx));
                
                try
                valWithAC = zeros(size(acVals,1),numel(newVals));
                valWithAC(:,~cidx & ~aidx & ~zidx) = valArray(ii*ones(size(valWithAC,1),1),:);
                valWithAC(:,cidx | aidx) = acVals;
                catch ME
                    rethrow(ME)
                end
                % then go through and find all the zs for each channel in
                % turn
                filenames = cell(size(valWithAC,1),1);
                noData = false(size(valWithAC,1),1);
                for jj = 1:size(valWithAC,1)
                    % then add the z information to the list
                    valWithZ = repmat(valWithAC(jj,:),[numel(newVals{zidx}),1]);
                    try
                    valWithZ(:,zidx) = newVals{zidx};
                    catch ME
                        rethrow(ME)
                    end
                    filenames{jj} = this.getFileNames(valWithZ,false);
                    
                    % go through and check for any NaNs in the filenames,
                    % which correspond to zslices which don't exist for
                    % this channel
                    % not always sure what should be done, ie should the
                    % slice be 'missing', or removed entirely?
                    % remove for now..
                    % but there may be an argument for adding missing
                    % slices to the cImage3DnC class
                    missingSlices = cellfun(@(x)any(isnan(x)),filenames{jj});
                    filenames{jj}(missingSlices) = [];
                    
                    noData(jj) = isempty(filenames{jj});
                    
                end
                
                filenames(noData) = [];
                
%                 chanvals = valWithAC(~noData,cidx);


                acvals = [valWithAC(~noData,aidx),valWithAC(~noData,cidx)];
                
                chanConstruct = arrayfun(@(x,y)this.ChannelLookup(x,y),acvals(:,1),acvals(:,2));
                
                colourIndex = acvals(:, 2);
                
                [~,ix] = sort(colourIndex,'ascend');
                % this is the order that needs applying to everything
                % - filenames
                % - NativeColours
                % - channels
                
                imgC3D{ii} = cImage3DnC(filenames(ix),this.PlatePath,this.NativeColours(colourIndex(ix)),...
                    chanConstruct(ix), [this.PixelSize, this.PixelSize, this.ZDistance],imageLabels{ii});
                
                info(ii) = this.getAC3DInfo(valWithAC(ii,:));
                
            end
            
        end
        
        function imInfo = getAC3DInfo(this,varargin)
            % get information about the chosen image
            % this info is then fed into a function which will generate the
            % export file name for each export method
            % USE THIS AS A TEMPLATE TO ROLL OUT TO THE OTHER IMAGE TYPES
            % AND THE OTHER IMAGE PARSERS
            
            
            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            % find the function that recursively converts the cell array to all the permutations
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
            % in the 3DnC case, separate multiple channels and z from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~aidx & ~cidx & ~zidx));
            
            tags = this.getImageLabel(valArray,'default');
            imInfo = struct('Label',tags{1},...
                'Well',this.ChoiceStruct.Choices{1}{valArray(:,1)},...
                'TimeLine',this.ChoiceStruct.Choices{2}(valArray(:,2)),...
                'TimePoint',this.ChoiceStruct.Choices{3}(valArray(:,3)),...
                'Field',this.ChoiceStruct.Choices{4}(valArray(:,4)));
            
            [imInfo.PlateID] = deal(this.PlateName);
        end

        function imgC3D = getC3DObj(this,varargin)
            % want to avoid having to replicate the code which determines the valArray
            % in every function
            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            
            for ii = 1:7
                if isempty(newVals{ii})
                    newVals{ii} = Inf;
                end
            end
            
            
            for ii = 1:numel(newVals)
                if any(~isfinite(newVals{ii}))
                    newVals{ii} = this.ChoiceStruct.Choices{ii};
                end
            end
            
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
            % it would be better for that to be handled here, so that one doesn't need
            % a GUI object in order to be able read in stacks
            
            % find the function that recursively converts the cell array to all the permutations

            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            aidx = strcmpi('action',this.ChoiceStruct.Labels);
            
            % in the 3DnC case, separate multiple channels and z from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~cidx & ~zidx));
            
            imageLabels = this.getImageLabel(valArray,'default');
            
            imgC3D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                valWithC = zeros(numel(newVals{cidx}),numel(newVals));
                valWithC(:,~cidx & ~zidx) = valArray(ii*ones(size(valWithC,1),1),:);
                valWithC(:,cidx) = newVals{cidx};
                
                % then go through and find all the zs for each channel in
                % turn
                filenames = cell(size(valWithC,1),1);
                for jj = 1:size(valWithC,1)
                    % then add the z information to the list
                    valWithZ = repmat(valWithC(jj,:),[numel(newVals{zidx}),1]);
                    valWithZ(:,zidx) = newVals{zidx};
                    
                    filenames{jj} = this.getFileNames(valWithZ,false);
                    
                    % go through and check for any NaNs in the filenames,
                    % which correspond to zslices which don't exist for
                    % this channel
                    % not always sure what should be done, ie should the
                    % slice be 'missing', or removed entirely?
                    % remove for now..
                    % but there may be an argument for adding missing
                    % slices to the cImage3DnC class
                    missingSlices = cellfun(@(x)any(isnan(x)),filenames{jj});
                    
                    
                    filenames{jj}(missingSlices) = [];
                    
%                     noData(jj) = isempty(filenames{jj});
                    
                end
                
%                 chanvals = valWithC(:,cidx);
                acvals = [valWithC(:,aidx),valWithC(:,cidx)];
                chanConstruct = arrayfun(@(x,y)this.ChannelLookup(x,y),acvals(:,1),acvals(:,2));
                
                colourIndex = acvals(:, 2);
                
                imgC3D{ii} = cImage3DnC(filenames,this.PlatePath,this.NativeColours(colourIndex),...
                    chanConstruct, [this.PixelSize, this.PixelSize, this.ZDistance],imageLabels{ii});
                
            end
            
        end

        function imObj = getSelectedImage(this,varargin)
            % from the ChoicesGUI object, ChP, return the appropriate image object
            % it therefore must be possible to determine from ChP whether we want
            % a single slice, 3D, multi channel, etc

            % it's better to separate the GUI-called methods from the programatic
            % or batch run methods, so that we don't have to compromise functionality

            % the current mode is stored in the blendMode property of the
            % ChoicesGUI, which can have a get method made if we like.
            
            % this is slightly unsatisfactory, because we're getting a
            % value from ChP and passing it back again, so maybe this could
            % all be done inside ChP instead - in that case, rather than
            % Loader.getSelectedImage(ChP), a better way round would be
            % ChP.getSelectedImage(Loader), avoiding lots of backwards and
            % forwards.
            if numel(varargin)==1 && isa(varargin{1},'ChoicesGUI')
                imMode = varargin{1}.blendMode;
            else
                imMode = 5;
            end
            
            
            switch imMode
                case 0
                    imObj = get2DObj(this,varargin{:});
                case 1
                    imObj = getC2DObj(this,varargin{:});
                case 2
                    imObj = get3DObj(this,varargin{:});
                case 3
                    imObj = getC3DObj(this,varargin{:});
                case 4
                    % will be action and channel, no z
                    % this means getting a bunch of C2Dobjects (or just the
                    % filenames) and stringing them together
                    imObj = getAC2DObj(this,varargin{:});
                case 5
                    % will be action, channel and z
                    imObj = getAC3DObj(this,varargin{:});
%                     keyboard
                otherwise
                    error('Unknown mode, something''s gone wrong!')
            end
            
        end
        
        
        function imInfo = getSelectedInfo(this,varargin)
            % from the ChoicesGUI object, ChP, return the appropriate image object
            % it therefore must be possible to determine from ChP whether we want
            % a single slice, 3D, multi channel, etc

            % it's better to separate the GUI-called methods from the programatic
            % or batch run methods, so that we don't have to compromise functionality

            % the current mode is stored in the blendMode property of the
            % ChoicesGUI, which can have a get method made if we like.
            
            % this is slightly unsatisfactory, because we're getting a
            % value from ChP and passing it back again, so maybe this could
            % all be done inside ChP instead - in that case, rather than
            % Loader.getSelectedImage(ChP), a better way round would be
            % ChP.getSelectedImage(Loader), avoiding lots of backwards and
            % forwards.
            if numel(varargin)==1 && isa(varargin{1},'ChoicesGUI')
                imMode = varargin{1}.blendMode;
            else
                imMode = 5;
            end
            
            switch imMode
                case 0
                    error('Not implemented yet');
                case 1
                    error('Not implemented yet');
                case 2
                    error('Not implemented yet');
                case 3
                    error('Not implemented yet');
                case 4
                    % will be action and channel, no z
                    % this means getting a bunch of C2Dobjects (or just the
                    % filenames) and stringing them together
                    imInfo = getAC2DInfo(this,varargin{:});
                case 5
                    % will be action, channel and z
                    imInfo = getAC3DInfo(this,varargin{:});
%                     keyboard
                otherwise
                    error('Unknown mode, something''s gone wrong!')
            end
            
        end
        
        function labelstr = getImageLabel(this,valArray,type)
            % choose what to display as a label for the image
            
            if nargin<3 || isempty(type)
                type = 'default';
            end
            
            labelstr = cell(size(valArray,1),1);
            
            wellind = strcmpi('well',this.ChoiceStruct.Labels);
            siteind = strcmpi('field',this.ChoiceStruct.Labels);
            
            for ii = 1:size(valArray,1)
                switch lower(type)
                    case 'short'
                        % use the well information only for now..
                        labelstr{ii} = sprintf('Well %s',...
                            this.ChoiceStruct.Choices{wellind}{valArray(ii,wellind)});
                    case 'default'
                         labelstr{ii} = sprintf('W:%s f:%d',...
                            this.ChoiceStruct.Choices{wellind}{valArray(ii,wellind)},...
                            this.ChoiceStruct.Choices{siteind}(valArray(ii,siteind)));
                    otherwise
                        error('Option not recognised')
                end
            end
            
            
        end

        function im = getSmallImage(this,dnsmple,varargin)
            % we might want the thumbnail to default to false unless we
            % specifically ask for it
            % in which case we would set it to false here, allow it to be
            % changed while the image is being read in, and then set it
            % back to false again.

            % ideally want to add shortcuts to the options, to save typing
            % them out constantly!
            if isempty(this.ImSize)
                error('Need to set image size first')
            end
            if nargin<2 || isempty(dnsmple)
                dnsmple = 10;
            end

            [newVals,newMode] = getValuesFromInputs(this,varargin{:});

            % return the current image
            siz = cellfun(@numel,this.ChoiceStruct(newMode).Choices);
            imidx = this.ChoiceStruct(newMode).ImMap(amcSub2Ind(siz,newVals));

            if ~(imidx>0)
                error('Image doesn''t exist')
            end
            filename = fullfile(this.PlatePath,this.ImNames{imidx});
            im = imread(filename,'PixelRegion',{[1,dnsmple,this.ImSize(1)],[1,dnsmple,this.ImSize(2)]});
        end
        
        function imObj = getCurrentEmptyImage(this,ChP)
            
            % need to make sure that all the appropriate channels and
            % zslices are read in.  Do this manually so that none of the
            % choices get changed
            
            cellvals = ChP.getCurrentValues;
            vals = expandCellIndices(cellvals);
            % manually set the channel and z values to Inf
            % the action should take care of itself
            
            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
            otheridx = find(~cidx & ~zidx);
            
            sizM = size(this.ChoiceStruct.ImMap);
            inds = amcSub2Ind(sizM(otheridx),vals(:,otheridx));
            
            T = joinDimensions(this.ChoiceStruct.ImMap,{find(cidx),find(zidx),otheridx(:)'});
            A = any(T(:,:,inds)>0,3);
            
            cvals = find(any(A,2));
            zvals = find(any(A,1));
            
            cellvals{cidx} = cvals;
            cellvals{zidx} = zvals;
            
            % the alternative here is to ensure that all actions are passed
            % to the bank - might make it slightly problematic bringing it
            % back again though
            % Perhaps the best approach would be to record the indices
            % rather than the image, and then these can be used to bring
            % things back from the bank
            if ChP.blendMode<4
                imObj = getC3DObj(this,cellvals);
            else
                imObj = getAC3DObj(this,cellvals);
            end
        end
        
        function X = name2props(this,s)
            % s has already been filtered to remove any non-images
            % because the order is fixed ,can do this all in one go -
            % although might want to be more general?

            temp1 = regexp(s,'bts:Column="(\d+)"','tokens','once');
            temp2 = regexp(s,'bts:Row="(\d+)"','tokens','once');
            temp3 = regexp(s,'bts:TimePoint="(\d+)"','tokens','once');
            temp4 = regexp(s,'bts:FieldIndex="(\d+)"','tokens','once');
            temp5 = regexp(s,'bts:ZIndex="(\d+)"','tokens','once');
            temp6 = regexp(s,'bts:TimelineIndex="(\d+)"','tokens','once');
            temp7 = regexp(s,'bts:ActionIndex="(\d+)"','tokens','once');
            temp8 = regexp(s,'bts:Ch="(\d+)"','tokens','once');

            % this needs to be robust enough that it won't crash if some of
            % the information is incomplete
            % check for missing info first, these should be flagged
            % perhaps?

            badinds = cellfun(@isempty,temp1) | cellfun(@isempty,temp2) | ...
                cellfun(@isempty,temp3) | cellfun(@isempty,temp4) | cellfun(@isempty,temp5) | ...
                cellfun(@isempty,temp6) | cellfun(@isempty,temp7) | cellfun(@isempty,temp8);

            %
            X = struct(...
                'well',rowcol2wellstr(str2double([temp2{~badinds}]'),str2double([temp1{~badinds}]'))...
                ,'timeline',num2cell(str2double([temp6{~badinds}]'))...
                ,'timepoint',num2cell(str2double([temp3{~badinds}]'))...
                ,'field',num2cell(str2double([temp4{~badinds}]'))...
                ,'action',num2cell(str2double([temp7{~badinds}]'))...
                ,'channel',num2cell(str2double([temp8{~badinds}]'))...
                ,'zslice',num2cell(str2double([temp5{~badinds}]'))...
                );

        end

        function [M,idx,choices,labels] = existmat(this,X)
            % using the structure from name2props, find out which
            % combinations of properties has an image associated with it.

            % first need to find the unique values for each property
            labels = fieldnames(X);

            % go through each label depending on the type of data (number
            % or string)
            choices = cell(numel(labels),1);
            idx = zeros(numel(X),numel(labels));
            for ii = 1:numel(labels)
                %  cell array for string options, normal array for numbers

                if ischar(X(1).(labels{ii}))
                    values = {X.(labels{ii})}';
                    choices{ii} = unique(values);

                    matchmat = strcmpi(values(:,ones(size(choices{ii}))), choices{ii}(:,ones(size(values)))');

                    try
                    idx(:,ii) = sum(bsxfun(@times,matchmat,(1:numel(choices{ii}))),2);
                    catch ME
                        rethrow(ME)
                    end
                else
                    values = [X.(labels{ii})]';
                    choices{ii} = unique(values);

                    idx(:,ii) = sum(bsxfun(@times,bsxfun(@eq,values,choices{ii}'),(1:numel(choices{ii}))),2);
                end



            end
            % idx should now be ready for accumarray
            % idx is a useful output to read off the channel, site, well
            % etc from a given image, and can be searched in reverse.

            % this is everything we need to create an IndexChoices object
            % to verify the inputs

            M0 = accumarray(idx,ones(size(idx,1),1),cellfun(@numel,choices)');

            if nnz(M0>1)==0
                M = accumarray(idx,(1:size(idx,1))',cellfun(@numel,choices)');
            else
                warning('Duplicate files detected, check the output to determine where')
                M = M0;
            end
        end

        function ChP = getChoiceGUI(this,parent)
            if nargin<2 % might want it to be empty at this point..
                parent = gfigure('Selection');
            end
            % the preferred display style for CV7000 experiments
            % ChP = BlendListPanelPlusWell(this.IC,'parent',parent);
            ChP = ActionBlendChoicesGUI(BlendHierImIC(this.ChoiceStruct.Labels,this.ChoiceStruct.Choices,...
                [],[],this.ChoiceStruct.ShortLabels,this.ChoiceStruct.ImMap>0),this.PlateDimensions,'parent',parent);
        end
        
        function batchObj = getBatchParser(this,imType)
            if nargin<2 || isempty(imType)
                imType = '3DnAC';
            end
            
            switch imType
                case '3DnC'
                    error('Not implemented yet')
                case '3DnAC'
                    batchObj = ThroughputYoko3DnAC(this);
                case '3D'
                    error('Not implemented yet')
                case '2DnC'
                    error('Not implemented yet')
                case '2DnAC'
                    error('Not implemented yet')
                case '2D'
                    error('Not implemented yet')
                otherwise
                    error('Unknown option')
            end
        end

        function noChannels = getTotalNumChan(this)
            noChannels = nnz(any(joinDimensions(this.ChoiceStruct.ImMap, {5, 6}), 3));
        end
        
        function setPixelSize(this)
            metaFileName = fullfile(this.PlatePath, 'MeasurementDetail.mrf');
 
            try
               tree = xmlread(metaFileName);
            catch
               error('Failed to read XML file %s.',metaFileName);
            end

            % Recurse over child nodes. This could run into problems 
            % with very deeply nested trees.
            try
               xmlStruct = parseChildNodes(this, tree);
            catch
               error('Unable to parse XML file %s.',metaFileName);
            end

            %%____________________________________________________________
            %%
            for i = 1:length(xmlStruct.Children)
                if strcmp(xmlStruct.Children(i).Name, 'bts:MeasurementChannel') == true

                    this.PixelSize = xmlStruct.Children(i).Attributes.HorizontalPixelDimension;
                    this.PixelSize = str2double(this.PixelSize);

                    break;
                end;
            end;
        end
        
        function pixelSize = getPixelSize(this)
            pixelSize = this.PixelSize;
        end
        
        function setZDistance(this)

%             aString = sprintf('%s\\*.mes', this.PlatePath);
            aString = fullfile(this.PlatePath,'*.mes');
            % modification to be platform independent
            
            
            temp = dir(aString);
            metaFile = temp.name;

            metaFile = fullfile(this.PlatePath, metaFile);
            
            try
               tree = xmlread(metaFile);
            catch
               error('Failed to read XML file %s.',metaFile);
            end

            % Recurse over child nodes. This could run into problems 
            % with very deeply nested trees.
            try
               xmlStruct = parseChildNodes(this, tree);
            catch
               error('Unable to parse XML file %s.',metaFile);
            end

        %%____________________________________________________________
        %%
        % Would regex be easier than 8 nested loops?
            for i = 1:length(xmlStruct.Children)
                if strcmp(xmlStruct.Children(i).Name, 'bts:Timelapse') == true

                    for j = 1:length(xmlStruct.Children(i).Children)
                        if strcmp(xmlStruct.Children(i).Children(j).Name, 'bts:Timeline') == true

                            for k = 1:length(xmlStruct.Children(i).Children(j).Children)
                                if strcmp(xmlStruct.Children(i).Children(j).Children(k).Name, 'bts:ActionList') == true

                                    for l = 1:length(xmlStruct.Children(i).Children(j).Children(k).Children)
                                        if strcmp(xmlStruct.Children(i).Children(j).Children(k).Children(l).Name, 'bts:ActionAcquire3D') == true

                                            this.ZDistance = xmlStruct.Children(i).Children(j).Children(k).Children(l).Attributes.SliceLength;
                                            this.ZDistance = str2double(this.ZDistance);
                                            break;
                                        end
                                    end
                                end
                            end
                        end
                    end;
                end;
            end;            
        end
        
        function zDistance = getZDistance(this)
            zDistance = this.ZDistance;
        end
        
        function setPlateDimensions(this)
%             error('Not completed yet')
            % aString = sprintf('%s\\*.mes', this.PlatePath);
            aString = fullfile(this.PlatePath,'*.mes');
            temp = dir(aString);
            
            s = textscan(fopen(fullfile(this.PlatePath, temp(1).name)),'%s','Delimiter','\n');
            
            s = s{1};

            % will likely need to replace name2props with code in the
            % constructor, since not every line in the file is a valid
            % image
            hasmes = regexp(s,'<bts:MeasurementSetting','once');
            ind = find(cellfun(@(x)~isempty(x),hasmes),1,'first');
            colstr = regexp(s{ind},'bts:Columns="(\d+)"','tokens','once');
            rowstr = regexp(s{ind},'bts:Rows="(\d+)"','tokens','once');
            
            this.PlateDimensions = [str2double(colstr{1}),str2double(rowstr{1})];
            % TODO
            
        end
    end
    methods (Static)
        function cvobj = browseForFile()
            
            %___________________________________________
            %   To select all the sub dirs
            platesDir = uigetdir('', 'Please select the folder which contains a plate.');

            if isequal(platesDir, 0)
                msgbox('Please indicate the location of plates.', 'Error', 'warn');
                cvobj = [];
                return;
            end;
            
            cvobj = ParserYokogawa(platesDir);
        end
        function cvobj = browseForFolder()
            %___________________________________________
            %   To select all the sub dirs
            platesDir = uigetdir('', 'Please select the folder which contains a plate.');

            if isequal(platesDir, 0)
                msgbox('Please indicate the location of plates.', 'Error', 'warn');
                cvobj = [];
                return;
            end;
            
            cvobj = ParserYokogawa(platesDir);
        end
    end
    
    
    methods (Access = private)
        % ----- Local function PARSECHILDNODES -----
        function children = parseChildNodes(this, theNode)
        % Recurse over node children.
            children = [];
            if theNode.hasChildNodes
               childNodes = theNode.getChildNodes;
               numChildNodes = childNodes.getLength;
               allocCell = cell(1, numChildNodes);

               children = struct(             ...
                  'Name', allocCell, ...
                  'Attributes', allocCell,    ...
                  'Children', allocCell);

                for count = 1:numChildNodes
                    theChild = childNodes.item(count-1);
                    children(count) = makeStructFromNode(this, theChild);
                end
            end
        end

        % ----- Local function MAKESTRUCTFROMNODE -----
        function nodeStruct = makeStructFromNode(this, theNode)
        % Create structure of node info.

            nodeStruct = struct(                        ...
               'Name', char(theNode.getNodeName),       ...
               'Attributes', parseAttributes(this, theNode),  ...
               'Children', parseChildNodes(this, theNode));
        end

        % ----- Local function PARSEATTRIBUTES -----
        function attributes = parseAttributes(this, theNode)
        % Create attributes structure.

            attributes = [];
            if theNode.hasAttributes
               theAttributes = theNode.getAttributes;
               numAttributes = theAttributes.getLength;

                %-- Delete the leading 'dts:' if any
                token = 'bts:';

                for count = 1:numAttributes
                    attrib = theAttributes.item(count-1);

                    %-- Delete the leading 'dts:' if any
                    aName = char(attrib.getName);

                    [~,endIndex] = regexp(aName,token);

                    if ~isempty(endIndex)
                        tempName = aName(endIndex + 1 : end);
                        attributes.(tempName) = char(attrib.getValue);
                    end
                end;
            end
        end            
    end %-- private.end
end
