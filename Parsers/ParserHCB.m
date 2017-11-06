classdef ParserHCB < ImgLoader
    % Loader for biological images
    % 
    % These tend to have parameters and values that need to be parsed to
    % determine what image needs to be read in
    % At the moment this is empty, but common and resuable code from the
    % ParserYokogawa will be brought over to here so that other Parsers can
    % use it
    
    properties
        
        PlatePath
        PlateName
        
        PlateDimensions
        
        NativeColours

        ChoiceStruct % will have one element for each mode
        % and contains ImMap, Labels, Choices, ShortLabels
        
        ImNames % list of image file names
        ImIndex
        
        ImSize
        
        PixelSize = [0,0];
        ZDistance = 0;
        
        ChannelLabels
        
    end
    methods
        
        imObj = getSelectedImage(this,cGUI);
        setPlateDimensions(this);
        
        function thumbObj = setThumbnail(this)

            cidx = strcmpi('channel',this.ChoiceStruct.Labels);
            colourIndex = this.ChoiceStruct.Choices{cidx};
            noChannels = nnz(colourIndex);
            
            W = floor(this.ImSize(2)/20);
            H = floor(this.ImSize(1)/20);

            thumbnailImage = zeros([H * this.PlateDimensions(2), W * this.PlateDimensions(1), noChannels], 'uint16');
            
            % add an extra channel containing the annotations
            textImage = zeros(size(thumbnailImage,1),size(thumbnailImage,2),'uint16');
            
            %-- rearranged to be (well, action, channel, z)
            
            joinorder = {find(strcmpi('well',this.ChoiceStruct.Labels)),...
                find(strcmpi('channel',this.ChoiceStruct.Labels))};
            zidx = find(strcmpi('zslice',this.ChoiceStruct.Labels));
            if ~isempty(zidx)
                joinorder = [joinorder,{zidx}];
            end
            
            S = joinDimensions(this.ChoiceStruct.ImMap,joinorder);
            % the function above permutes and reshapes so that the new
            % order is well, channel, zslice, then everything else
            % in 1 dimension
            
            if ~isempty(zidx)
                % Choose the middle z-slice
                S = ordChoice(S,0.5,3); % 50%, 3rd dimension
            end
            
            progressBarAPI('init',nnz(S));
            
            [wellRow, wellCol] = wellstr2rowcol(this.ChoiceStruct.Choices{1});
            
            for i = 1:size(S, 1)
                addtext = false;
                
                for j = 1:size(S, 2)

                    if S(i, j)==0
                        continue;
                    end


                    imFileName = fullfile(this.PlatePath, this.ImNames{S(i,j)});

                    aThumbnail = imresize(imread(imFileName, ...
                                                 'PixelRegion', {[1 10 this.ImSize(1)],[1 10 this.ImSize(2)]}),...
                                                 [H W]);

                    thumbnailImage((wellRow(i)-1)*H+1:wellRow(i)*H, (wellCol(i)-1)*W+1:wellCol(i)*W, j) = aThumbnail;                         

                    progressBarAPI('increment');

                    addtext = true;
                end;
                
                if addtext
                    textRegion = zeros(H,W,'uint16');
                    
                    textRegion = AddTextToImage(textRegion,this.ChoiceStruct.Choices{1}{i},...
                        [1,1],65536,'Arial',ceil(H/4));
                    
                    textImage((wellRow(i)-1)*H+1:wellRow(i)*H, (wellCol(i)-1)*W+1:wellCol(i)*W) = textRegion;                         
                        
                end
            end;
            
            revisedColour = this.NativeColours;
            
            thumbObj = cImage2DnC([], [],[revisedColour;{[0.99,0.99,0.99]}], [(1:size(thumbnailImage,3))';NaN],...
                [this.PixelSize*20, this.PixelSize*20], 'Plate',...
                [squeeze(num2cell(thumbnailImage,[1, 2]));{textImage}]);            
            
            progressBarAPI('finish');
        end
        
        function newVals = getValuesFromInputs(this,varargin)
            % convert the parameter-value pairs in varargin to a vector based on the
            % order in the labels
            % newVals is a cell array of values, reflecting the that that multiple
            % choices may become possible

            args = varargin;
            % allow the values to be supplied directly
            if numel(args)==1
                if isa(args{1},'ChoicesGUI')
                    newVals = getCurrentValues(args{1});
                elseif isstruct(args{1})
                    % can we get what we need from the structure?
                    fieldNames = fieldnames(args{1});
                    newVals = num2cell(Inf*ones(1,numel(this.ChoiceStruct.Labels)));
                    for ii = 1:numel(newVals)
                        ind = find(strcmpi(this.ChoiceStruct.Labels{ii},fieldNames));
                        if ~isempty(ind)
                            val = args{1}.(fieldNames{ind});
                            if ischar(val)
                                % need to find the choice which matches the
                                % string provided
                                newVals{ii} = find(strcmpi(val,this.ChoiceStruct.Choices{ii}));
                            else
                                newVals{ii} = val;
                            end
                            
                        end
                    end
                elseif ~iscell(args{1})
                    newVals = num2cell(args{1}(:)');
                else
                    newVals = args{1};
                end
            else

                count = 1;

                newVals = cell(1,numel(this.ChoiceStruct.Labels));
                while count<numel(args)
                    currlab = args{count};
                    currval = args{count+1};

                    ind = strcmpi(currlab,this.ChoiceStruct.Labels) | strcmpi(currlab,this.ChoiceStruct.ShortLabels);
                    if nnz(ind)==1
                        if ~ischar(currval)
                            newVals{ind} = currval;
                        else
                            newVals{ind} = find(strcmpi(currval,this.ChoiceStruct.Choices{ind}));
                        end
                    else
                        warning('ambiguous choice, skipping')
                    end
                    count = count + 2;
                end
            end
            % we then have to go through the list to find any Infs, and replace them
            % with the whole range of availabilities
            if numel(newVals)<numel(this.ChoiceStruct.Choices)
                newVals((numel(newVals)+1):numel(this.ChoiceStruct.Choices)) = {Inf};
            end
            for ii = 1:numel(newVals)
                if isempty(newVals{ii})
                    newVals{ii} = Inf;
                end
                if any(~isfinite(newVals{ii}))
                    % there is a specific case that if an Inf has been sent
                    % for the isThumb (ie thumbnail) field, we don't want
                    % to return the image and the thumbnail
                    
                    if strcmpi(this.ChoiceStruct.Labels{ii},'isthumb')
                        newVals{ii} = 1;
                    else
                        newVals{ii} = this.ChoiceStruct.Choices{ii};
                    end
                end
            end
            
        end
        
        function filenames = getFileNames(this,valArray,incPath)
            if nargin<3 || isempty(incPath)
                incPath = true;
            end
            % this function returns a cell array of file names, one element for each
            % row of valArray

            % return the current image
            siz = cellfun(@numel,this.ChoiceStruct.Choices); % perhaps this can be stored rather than being calculated every time
            imidx = this.ChoiceStruct.ImMap(amcSub2Ind(siz,valArray));

            filenames = cell(numel(imidx),1);
            for ii = 1:numel(imidx)
                if ~(imidx(ii)>0)
                    filenames{ii} = NaN;
                else
                    if incPath
                        filenames{ii} = fullfile(this.PlatePath,this.ImNames{imidx(ii)});
                    else
                        filenames{ii} = this.ImNames{imidx(ii)}; % this can probably be taken out of the loop
                    end
                end
            end
        end
        
        function im = getImage(this,varargin)
            % return the requested image

            newVals = getValuesFromInputs(this,varargin{:});
            % for now, any missing values throw an error
            if any(cellfun(@isempty,newVals))
                error('Missing option, this is currently an error')
            end

            % also, if the value is Inf, this is supposed to correspond to choose all
            % but leave that for later..
% %             for ii = 1:numel(newVals)
% %                 if isinf(newVals{ii})
% %                     % need to convert it to all available
% %                     
% %                 end
% %             end
            
            % find the function that recursively converts the cell array to all the permutations

            valArray = expandCellIndices(newVals);

            filenames = getFileNames(this,valArray);
            im = cell(numel(filenames));
            for ii = 1:numel(filenames)
                im{ii} = imread(filenames{ii});
            end
        end
        
        
        function aName = getTitle(this)
            aName = this.PlateName;
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
            
            % in the 2D case, we want a cell array of every image requested
            filenames = getFileNames(this,valArray);
            % but some of these can potentially be NaNs, if we've requested
            % multiple actions, etc, so the NaNs have to be weeded out and
            % removed
            
            filenames(cellfun(@(x) isscalar(x) && isnan(x),filenames)) = [];
            imageLabels = this.getImageLabel(valArray,'short');
            
            
            img2D = cell(numel(filenames),1);
            for ii = 1:numel(filenames)
                img2D{ii} = cImage2D(filenames{ii},this.NativeColours{valArray(ii,cidx)},...
                    valArray(ii,cidx), [this.PixelSize, this.PixelSize],imageLabels{ii});
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
            
            valArray = expandCellIndices(newVals(~zidx));
            
            imageLabels = this.getImageLabel(valArray,'short');
            
            img3D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                valWithZ = zeros(numel(newVals{zidx}),numel(newVals));
                valWithZ(:,~zidx) = valArray(ii*ones(size(valWithZ,1),1),:);
                valWithZ(:,zidx) = newVals{zidx};
                
                filenames = this.getFileNames(valWithZ,false);
                
                img3D{ii} = cImage3D(filenames,this.PlatePath,this.NativeColours{valArray(ii,cidx)},...
                    valArray(ii,cidx), [this.PixelSize, this.PixelSize],imageLabels{ii});
                
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
            
            % in the 2DnC case, separate multiple channels from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~cidx));
            
            imageLabels = this.getImageLabel(valArray,'short');
            
            imgC2D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                valWithC = zeros(numel(newVals{cidx}),numel(newVals));
                valWithC(:,~cidx) = valArray(ii*ones(size(valWithC,1),1),:);
                valWithC(:,cidx) = newVals{cidx};
                
                filenames = this.getFileNames(valWithC,false);
                
                chanvals = valWithC(:,cidx);
                imgC2D{ii} = cImage2DnC(filenames,this.PlatePath,this.NativeColours(chanvals),...
                    chanvals, [this.PixelSize, this.PixelSize],imageLabels{ii});
                
            end
        end
        function imInfo = getC2DInfo(this,varargin)

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
            
            % in the 2DnC case, separate multiple channels from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~cidx));
            
            imageLabels = this.getImageLabel(valArray,'short');
            
            for ii = 1:size(valArray,1)
                % need to check each choice depending on whether it's a
                % cell array or a normal array
                tempstruct = struct('Label',imageLabels{1});
                for jj = 1:size(valArray,2)
                    if ~cidx(jj) % we've asked for all channels, so don't record channel information
                        if iscell(this.ChoiceStruct.Choices{jj})
                            tempstruct.(this.ChoiceStruct.Labels{jj}) = ...
                                this.ChoiceStruct.Choices{jj}{valArray(ii,jj)};
                        else
                            tempstruct.(this.ChoiceStruct.Labels{jj}) = ...
                                this.ChoiceStruct.Choices{jj}(valArray(ii,jj));
                        end
                    end
                end
                
                if ii==1
                    imInfo = tempstruct;
                else
                    imInfo = [imInfo;tempstruct];
                end
            end
            
            
        end
        
        function imgC3D = getC3DObj(this,varargin)
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
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
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
                    valWithZ = repmat(valWithC,[numel(newVals{zidx}),1]);
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
                
                chanvals = valWithC(:,cidx);
                imgC3D{ii} = cImage3DnC(filenames,this.PlatePath,this.NativeColours(chanvals),...
                    chanvals, [this.PixelSize, this.PixelSize],imageLabels{ii});
                
            end
            
        end

        
        function labelstr = getImageLabel(this,valArray,type)
            % choose what to display as a label for the image
            
            if nargin<3 || isempty(type)
                type = 'default';
            end
            
            labelstr = cell(size(valArray,1),1);
            
            wellind = strcmpi('well',this.ChoiceStruct.Labels);
            siteind = strcmpi('site',this.ChoiceStruct.Labels);
            
            for ii = 1:size(valArray,1)
                switch lower(type)
                    case 'short'
                        % use the well information only for now..
                        labelstr{ii} = sprintf('Well %s',...
                            this.ChoiceStruct.Choices{wellind}{valArray(ii,wellind)});
                    case 'default'
                         labelstr{ii} = sprintf('W:%s s:%d',...
                            this.ChoiceStruct.Choices{wellind}{valArray(ii,wellind)},...
                            this.ChoiceStruct.Choices{siteind}(valArray(ii,siteind)));
                    otherwise
                        error('Option not recognised')
                end
            end
            
            
        end
        
        function batchObj = getBatchParser(this,imType)
            if nargin<2 || isempty(imType)
                imType = '2DnC';
            end
            
            switch imType
                case '3DnC'
                    error('Not implemented yet')
                case '3D'
                    error('Not implemented yet')
                case '2DnC'
                    batchObj = ThroughputIX2DnC(this);
                case '2D'
                    error('Not implemented yet')
                otherwise
                    error('Unknown option')
            end
        end
        
        function N = getTotalNumChan(this)
            % the total number in this context will depend on the current
            % action mode - there is the potential that multiple channel
            % numbers exist within different actions

            chanidx = strcmpi('channel',this.ChoiceStruct.Labels);
            N = max(this.ChoiceStruct.Choices{chanidx});

        end
        
        function setImsiz(this,ImSize)
            if nargin>1 && ~isempty(ImSize)
                this.ImSize = ImSize;
            else
                this.detectImsiz();
            end
        end

        function detectImsiz(this)
            % might be worth getting some other information while we're at
            % it, such as pixel size, image type etc..
            
            % make sure that it's not a thumbnail image that we get the
            % size from!
            thumbdim = find(strcmpi('isthumb',this.ChoiceStruct.Labels));
            if isempty(thumbdim)
                temp = find(this.ChoiceStruct.ImMap,1,'first');
                imind = this.ChoiceStruct.ImMap(temp);
            else
                temp = joinDimensions(this.ChoiceStruct.ImMap,{thumbdim});
                % first dimension = thumb or not
                % second dimension = everything else
                temp2 = find(temp(1,:),1,'first'); % find the first non-thumb image
                
                imind = temp(1,temp2);
            end
            
            if ispc
% %                 fid = tifflib('open',fullfile(this.PlatePath,this.ImNames{imind}),'r');
% %                 meta = tifflib('retrieveMetadata',fid);
% %                 tifflib('close',fid);
% % 
% %                 this.ImSize = [meta.ImageLength,meta.ImageWidth];
                % use the newer MATLAB Tiff class
                tiffobj = Tiff(fullfile(this.PlatePath,this.ImNames{imind}),'r');
                this.ImSize = [tiffobj.getTag('ImageLength'),tiffobj.getTag('ImageWidth')];
                tiffobj.close;
            else
                % just open the first image
                tempim = imread(fullfile(this.PlatePath,this.ImNames{imind}));
                this.ImSize = [size(tempim,1),size(tempim,2)];
            end
        end
        
        function imObj = getCurrentEmptyImage(this,ChP)
            
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
           
            % what if there is no z?  Presumably it should be stored as
            % a 2DnC image instead?

            if nnz(zidx)>0
                imObj = getC3DObj(this,ChP);
            else
                imObj = getC2DObj(this,ChP);
            end
        end
        
        function labels = getChoiceLabels(this)
            labels = this.ChoiceStruct.Labels;
        end
        function labels = getShortLabels(this)
            labels = this.ChoiceStruct.ShortLabels;
        end
        
% %         function imObj = getCurrentEmptyImage(this,ChP)
% %             % this is used to store image references ready for segmentation
% %             
% %             % need to reconstruct the list of filenames to use to
% %             % create the cImage3DnC object
% %             % get the indices directly from the ImMap, using the
% %             % hierarchical approach
% %             cidx = strcmpi('channel',this.ChoiceStruct.Labels);
% %             zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
% %             
% %             newVals = getValuesFromInputs(this,ChP);
% %             
% %             % Multiple images can be returned in a cell array - however, if
% %             % multiple z (or c) images have been asked for, this will be
% %             % interpreted as a single 3D or multichannel image instead.
% %             % The choice of how many images we want can be decided by
% %             % looking at the ChP.blendMode value.
% %             % This will need to be fixed at some point, but not urgent
% %             % Also, what is the requirement for when several channels or z
% %             % slices are selected?  Presumably we don't want them to be
% %             % opened separately?
% %             
% %             if ChP.blendMode<4
% %                 valArray = expandCellIndices(newVals(~cidx & ~zidx));
% %                 % for now, any missing values throw an error
% %                 if any(cellfun(@isempty,newVals))
% %                     error('Missing option, this is currently an error')
% %                 end
% %                 
% %                 % what if there is no z?  Presumably it should be stored as
% %                 % a 2DnC image instead?
% %                 
% %                 if nnz(zidx)>0
% %                     M3D = joinDimensions(this.ChoiceStruct.ImMap,{find(cidx),find(zidx)});
% %                     % third dimension is everything else (aside from channel and
% %                     % z)
% %                     M0 = M3D(:,:,amcSub2Ind(cellfun(@numel,this.ChoiceStruct.Choices(~cidx & ~zidx)),valArray));
% % 
% %                     imObj = cell(size(M0,3),1);
% %                     imageLabels = this.getImageLabel(valArray,'default');
% %             
% %                     for ii = 1:size(M0,3)
% %                         cinds = find(any(M0(:,:,ii),2));
% %                         filenames = cell(numel(cinds));
% %                         for jj = 1:numel(filenames)
% %                             zinds = M0(cinds(jj),:,ii)>0;
% %                             filenames{jj} = this.ImNames(M0(cinds(jj),zinds,ii));
% %                             % ignores missing slices - needs changing slightly if
% %                             % we want to keep missing slices
% %                         end
% %                         
% %                         imObj{ii} = cImage3DnC(filenames,this.PlatePath, this.NativeColours(cinds), cinds,...
% %                             [this.PixelSize, this.PixelSize],imageLabels{ii});
% %                     end
% %                 else
% %                     % No z, make it a 2DnC instead
% %                     M2D = joinDimensions(this.ChoiceStruct.ImMap,{find(cidx)});
% %                     % third dimension is everything else (aside from channel and
% %                     % z)
% %                     M0 = M2D(:,amcSub2Ind(cellfun(@numel,this.ChoiceStruct.Choices(~cidx & ~zidx)),valArray));
% % 
% %                     imObj = cell(size(M0,2),1);
% %                     imageLabels = this.getImageLabel(valArray,'default');
% %             
% %                     for ii = 1:size(M0,2)
% %                         cinds = find(any(M0(:,ii),2));
% %                         filenames = this.ImNames(M0(cinds,:));
% %                         
% %                         imObj{ii} = cImage2DnC(filenames,this.PlatePath, this.NativeColours(cinds), cinds,...
% %                             [this.PixelSize, this.PixelSize],imageLabels{ii});
% %                     end
% %                 end
% %             else
% %                 aidx = strcmpi('action',this.ChoiceStruct.Labels);
% %                 valArray = expandCellIndices(newVals(~cidx & ~zidx & ~aidx));
% %                 % for now, any missing values throw an error
% %                 if any(cellfun(@isempty,newVals))
% %                     error('Missing option, this is currently an error')
% %                 end
% % 
% %                 M3D = joinDimensions(this.ChoiceStruct.ImMap,{[find(cidx),find(aidx)],find(zidx)});
% %                 % third dimension is everything else (aside from channel and
% %                 % z)
% %                 M3D = M3D(any(M3D(:,:),2),:,:); % only keep the action channel combos that have images
% %                 M0 = M3D(:,:,amcSub2Ind(cellfun(@numel,this.ChoiceStruct.Choices(~cidx & ~zidx & ~aidx)),valArray));
% % 
% %                 imObj = cell(size(M0,3),1);
% %                 imageLabels = this.getImageLabel(valArray,'default');
% %             
% %                 for ii = 1:size(M0,3)
% %                     
% %                     cinds = find(any(M0(:,:,ii),2));
% %                     filenames = cell(numel(cinds),1);
% %                     for jj = 1:numel(filenames)
% %                         zinds = M0(cinds(jj),:,ii)>0;
% %                         filenames{jj} = this.ImNames(M0(cinds(jj),zinds,ii));
% %                         % ignores missing slices - needs changing slightly if
% %                         % we want to keep missing slices
% %                     end
% %                     try
% %                     imObj{ii} = cImage3DnC(filenames,this.PlatePath, this.NativeColours(cinds), cinds, [this.PixelSize, this.PixelSize],imageLabels{ii});
% %                     catch ME
% %                         rethrow(ME)
% %                     end
% %                 end
% %             end
% %             
% %             
% %         end

    end
    
end