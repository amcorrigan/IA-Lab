classdef ParserBioFormats < ImgLoader
    % Parse data using the bioformats wrappers
    %
    % Since we want the bioformats to do the work for us, this will be
    % quite different from the other HCB-style parsers
    % This may become the standard approach, with the hierarchical image
    % handling taken care of by the bioformats java class methods
    
    % Some of the properties are quite obscure and buried within the
    % java-based metadata
    % For now, we'll assume that there is only one plate, and so all the
    % plateindex values will be 0, but in theory this should generalise
    % quite easily for multiple plates
    
    properties
        PlatePath
        PlateName
        ImFileFullPath
        
        PlateDimensions
        
        BFReader
        
%         BFMetadata % can no longer use this, it isn't accurate!
        
        Rows
        Columns
        WellFieldMap
        
        ChoiceStruct
        
        PixelSize = [0,0];
        ZDistance = 0;
        
        ChannelLabels
        
        ImSize
        
        NativeColours
    end
    methods
        function this = ParserBioFormats(imfile)
            % start with the use case that we have, ie reading a single C01
            % image parses the whole plate
            
            this.BFReader = bfGetReader(imfile);
            
            % populate the platename and platepath, and also store the
            % image file so that the reader can be recreated if the parser
            % is saved and reloaded
            
            this.ImFileFullPath = syspath(imfile);
            this.PlatePath = fileparts(this.ImFileFullPath);
            [~,this.PlateName] = fileparts(this.PlatePath);
            
            this.retrieveMetadata();
            
            % Not sure if channel colours are stored in the bioformats
            % metadata?
            
            tempcolours = {[0,0,1];[0,1,0];[1,0,0];[1,1,1]};
            this.NativeColours = tempcolours(mod((1:numel(this.ChoiceStruct.Choices{4}))-1,numel(tempcolours))+1);
        end
        
        function retrieveMetadata(this)
            % get a list of which well corresponds to which entry in the
            % reader
            
            % Presumably if there are multiple fields, then there will be
            % duplicate well entries?
            % These need to be found and assigned with field numbers
            
            % For the latest version of the bioformats jars, the metadata
            % isn't accurate for C01 files (only 368 wells listed out of
            % 384, seems that the first column get missed out..)
            % Therefore, if there is well information we need to try to
            % parse it ourselves
            
            % implement this on a case by case basis, using the file type
            jnames = this.BFReader.getSeriesUsedFiles();
            filename = char(jnames(1));
            [pth,fname,ext] = fileparts(filename);
            if strcmpi(ext,'.c01')
                this.getC01WellInfo();
            else
                this.Rows = (1:this.BFReader.getSeriesCount())';
                this.Columns = ones(this.BFReader.getSeriesCount(),1);
            end
            
            
            
% %             this.Rows = arrayfun(@(x)this.BFMetadata.getWellRow(0,x).getValue,...
% %                 (1:this.BFMetadata.getWellCount(0))'-1)+1;
% %             this.Columns = arrayfun(@(x)this.BFMetadata.getWellColumn(0,x).getValue,...
% %                 (1:this.BFMetadata.getWellCount(0))'-1)+1;
            
            % calculate the reverse, so that indices can be looked up
            % easily
            
            % haven't found where the plate dimensions are stored, so just
            % use the max of each for now
            this.PlateDimensions = [max(this.Columns),max(this.Rows)];
            % need to check this way round is consistent with other parsers
            
            this.WellFieldMap = NaN*zeros(this.PlateDimensions([2,1]));
            
            temp = accumarray([this.Rows,this.Columns],(1:numel(this.Rows))',...
                this.PlateDimensions([2,1]),@(x){x(:)'},{NaN});
            % for fields in the same well, need a way of differentiating
            % them..
            this.WellFieldMap = amcCell2Mat(temp,NaN,1);
            tempsiz = size(this.WellFieldMap);
            this.WellFieldMap = reshape(this.WellFieldMap,[this.PlateDimensions([2,1]),tempsiz(2:end)]);
            
%             this.WellFieldMap(amcSub2Ind(this.PlateDimensions,[this.Rows,this.Columns])) = (1:numel(this.Rows))';
            
            % Now we want to populate the choicestruct structure, so that
            % the GUI will be able to know what choices are available
            
            this.ChoiceStruct.Labels = {'Well','Field','Timepoint','Channel','ZSlice'};
            this.ChoiceStruct.ShortLabels = {'w','f','t','c','z'};
            
            this.ChoiceStruct.Choices{1} = unique(rowcol2wellstr(this.Rows,this.Columns));
            % rowcol2wellstr still doesn't handle 1536 layout names
            
            this.ChoiceStruct.Choices{2} = (1:size(this.WellFieldMap,3))';
            
            % this isn't going to cut it for different size images..
            % either needs to be hierarchical, or find the max
            % just do the max for now..
            maxT = 0;
            maxC = 0;
            maxZ = 0;
            for ii = 1:this.BFReader.getSeriesCount
                this.BFReader.setSeries(ii-1);
                maxT = max(maxT,this.BFReader.getSizeT());
                maxC = max(maxC,this.BFReader.getSizeC());
                maxZ = max(maxZ,this.BFReader.getSizeZ());
            end
            this.ChoiceStruct.Choices{3} = (1:maxT)';
            this.ChoiceStruct.Choices{4} = (1:maxC)';
            this.ChoiceStruct.Choices{5} = (1:maxZ)';
            
% %             this.ChannelLabels = (1:this.BFReader.getSizeC());
            this.ChannelLabels = arrayfun(@num2str,(1:this.BFReader.getSizeC())','uni',false);
            
            this.ImSize = [this.BFReader.getSizeX(),this.BFReader.getSizeY()];
            % still don't know what images are present in a hierarchical
            % way (ie there could be different numbers of z-slices or
            % channels in each field/well, or different numbers of fields
            % in each well.
            % The only way to know this in advance is to go through the
            % metadata setting the series each time to build up a 5D map
            % matrix
            % Until then, we'll have to assume that the image acquisition
            % is rectangular
        end
        
        function getC01WellInfo(this)
            this.Rows = NaN*zeros(this.BFReader.getSeriesCount,1);
            this.Columns = NaN*zeros(this.BFReader.getSeriesCount,1);
            
            for ii = 1:this.BFReader.getSeriesCount;
                this.BFReader.setSeries(ii-1);
                str = this.BFReader.getSeriesUsedFiles();
                [~,filename] = fileparts(char(str(1)));
                s = regexp(filename,'_(?<well>[A-Z]\d{2})','names');
                
                [r,c] = wellstr2rowcol(s.well);
                
                this.Rows(ii) = r;
                this.Columns(ii) = c;
            end
        end
        
        function thumbObj = setThumbnail(this)

            noChannels = numel(this.ChannelLabels);
            
            % could set a fixed size instead..
% %             W = floor(this.ImSize(2)/20);
% %             H = floor(this.ImSize(1)/20);
            
            W = 160;
            H = round(this.ImSize(1)/this.ImSize(2)*160);

            thumbnailImage = zeros([H * this.PlateDimensions(1), W * this.PlateDimensions(2), noChannels], 'uint16');
            
            % add an extra channel containing the annotations
            textImage = zeros(size(thumbnailImage,1),size(thumbnailImage,2),'uint16');
            
            % go through the wells that are present
            
            
            
            
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
        
        
        function linearInd = calcImageIndex(this,t,c,z)
            try
                linearInd = this.BFReader.getIndex(z - 1, c -1, t - 1) + 1;
            catch ME
                % ought to check the error message to ensure that it's an
                % out of range error.
                linearInd = NaN;
            end
           
        end
        
        function refreshReader(this)
            % use the stored file location to recreate the Reader object
            this.BFReader = bfGetReader(this.ImFileFullPath);
        end
        
        function imgC2D = getC2DObj(this,varargin)
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
                
                % need to make sure we've set the series before getting the
                % image indices
                
                % the series can potentially be different for each image
                % requested
                
                %-- Bioformat setseriers can NOT handle missing files, e.g.
                %*o1.C01, so this need fix, so far yinhai found a temp fix:
                %                 data = bfopen(aJohannaResultFile);
                %                 
                %                 if size(data, 1) == 1
                %                     series1 = data{1, 1};
                %                     htsImage = series1{1, 1};
                %                 else
                %                     for kk = 1:size(data, 1)
                %                         aString = data{kk, 1}{1, 2};
                %                         aSubString = sprintf('; Well %s, ', wellID);
                % 
                %                         if isempty(strfind(aString, aSubString)) == false
                %                             series1 = data{kk, 1};
                %                             htsImage = series1{1, 1};
                % 
                %                             break;
                %                         end;
                %                     end;
                %                 end;
                
                
                [r,c] = wellstr2rowcol(this.ChoiceStruct.Choices{1}{valWithC(1,1)});
                seriesInd = this.WellFieldMap(r,c,valWithC(1,2));
                this.BFReader.setSeries(seriesInd-1);
                imdata = cell(size(valWithC,1),1);
                for jj = 1:size(valWithC,1)
                    % fixed index positions for now
                    imind = this.calcImageIndex(valWithC(jj,3),valWithC(jj,4),valWithC(jj,5));
                    
                    % not necessarily separate files for each image, so
                    % have to load them directly
                    imdata{jj} = bfGetPlane(this.BFReader,imind);
                end
                
                chanvals = valWithC(:,cidx);
                imgC2D{ii} = cImage2DnC([],[],this.NativeColours(chanvals),...
                    chanvals, [this.PixelSize, this.PixelSize],imageLabels{ii},imdata);
                
            end
        end
        function imInfo = getC2DInfo(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % might be able to do this generally, without knowing what the
            % structure of the experiment is.  This might be an option to
            % move to the superclass
            
            imInfo = struct;
            
            for ii = 1:min(numel(newVals),numel(this.ChoiceStruct.Labels))
                % for C2D, don't need to know the channel, because it
                % should be all channels..
                if ~strcmpi(this.ChoiceStruct.Labels{ii},'channel')
                    
                    val = this.ChoiceStruct.Choices{ii}(newVals{ii});
                    if iscell(val)
                        val = val{1};
                    end

                    imInfo.(this.ChoiceStruct.Labels{ii}) = val;
                end
            end
            
            imInfo.PlateID = this.PlateName;
        end
        function imgC3D = getC3DObj(this,varargin)
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
            
            % in the 2DnC case, separate multiple channels from the other
            % multiple choices
            valArray = expandCellIndices(newVals(~cidx & ~zidx));
            
            imageLabels = this.getImageLabel(valArray,'short');
            
            imgC3D = cell(size(valArray,1),1);
            for ii = 1:size(valArray,1)
                valWithC = zeros(numel(newVals{cidx}),numel(newVals));
                valWithC(:,~cidx & ~zidx) = valArray(ii*ones(size(valWithC,1),1),:);
                valWithC(:,cidx) = newVals{cidx};
                
                % need to make sure we've set the series before getting the
                % image indices
                
                % the series can potentially be different for each image
                % requested
                [r,c] = wellstr2rowcol(this.ChoiceStruct.Choices{1}{valWithC(1,1)});
                seriesInd = this.WellFieldMap(r,c,valWithC(1,2));
                this.BFReader.setSeries(seriesInd-1);
                
                
                imdata = cell(size(valWithC,1),1);
                for jj = 1:size(valWithC,1)
                    % fixed index positions for now
                    
                    % now need to fill in the z slices required
                    valWithZ = zeros(numel(newVals{zidx}),numel(newVals));
                    valWithZ(:,~zidx) = valWithC(jj*ones(size(valWithZ,1),1),~zidx);
                    valWithZ(:,zidx) = newVals{zidx};
                    
                    % check here which z indices are out of range
                    maxZ = this.BFReader.getSizeZ();
                    valWithZ(valWithZ(:,zidx)>maxZ,:) = [];
                    
                    imdata{jj} = zeros(this.BFReader.getSizeX(),this.BFReader.getSizeY(),...
                        size(valWithZ,1));
                    for kk = 1:size(valWithZ,1)
                        imind = this.calcImageIndex(valWithZ(kk,3),valWithZ(kk,4),valWithZ(kk,5));

                        % not necessarily separate files for each image, so
                        % have to load them directly
                        imdata{jj}(:,:,kk) = bfGetPlane(this.BFReader,imind);
                    end
                end
                
                chanvals = valWithC(:,cidx);
                imgC3D{ii} = cImage3DnCNoFile(imdata,this.NativeColours(chanvals),...
                    chanvals, [this.PixelSize, this.PixelSize],imageLabels{ii});
                
            end
        end
        function imInfo = getC3DInfo(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % might be able to do this generally, without knowing what the
            % structure of the experiment is.  This might be an option to
            % move to the superclass
            
            imInfo = struct;
            
            for ii = 1:min(numel(newVals),numel(this.ChoiceStruct.Labels))
                % for C2D, don't need to know the channel, because it
                % should be all channels..
                if ~strcmpi(this.ChoiceStruct.Labels{ii},'channel')
                    
                    val = this.ChoiceStruct.Choices{ii}(newVals{ii});
                    if iscell(val)
                        val = val{1};
                    end

                    imInfo.(this.ChoiceStruct.Labels{ii}) = val;
                end
            end
            
            imInfo.PlateID = this.PlateName;
        end
        
        function batchObj = getBatchParser(this,imType)
            if nargin<2 || isempty(imType)
                if this.BFReader.getSizeZ()>1
                    imType = '3DnC';
                else
                    imType = '2DnC';
                end
            end
            
            switch imType
                case '3DnC'
                    batchObj = ThroughputBioFormats3DnC(this);
                case '3DnAC'
                    error('Not implemented yet')
                case '3D'
                    error('Not implemented yet')
                case '2DnC'
                    batchObj = ThroughputBioFormats2DnC(this);
                case '2DnAC'
                    error('Not implemented yet')
                case '2D'
                    error('Not implemented yet')
                otherwise
                    error('Unknown option')
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
                        wellval = valArray(ii,wellind);
                        if isnumeric(wellval)
                            labelstr{ii} = sprintf('Well %s',...
                                this.ChoiceStruct.Choices{find(wellind)}{wellval});
                        else
                            labelstr{ii} = sprintf('Well %s',wellval);
                        end
                    case 'default'
                         labelstr{ii} = sprintf('W:%s s:%d',...
                            this.ChoiceStruct.Choices{find(wellind)}{valArray(ii,wellind)},...
                            this.ChoiceStruct.Choices{find(siteind)}(valArray(ii,siteind)));
                    otherwise
                        error('Option not recognised')
                end
            end
            
            
        end
        
        function newVals = getValuesFromInputs(this,varargin)
            % convert the parameter-value pairs in varargin to a vector based on the
            % order in the labels
            % newVals is a cell array of values, reflecting the that that multiple
            % choices may become possible
            
            % this might be a good place to check the reader, since it
            % should be called every time
            if isempty(this.BFReader)
                this.refreshReader();
            end

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
                % also need to check if the well (or any other option) has
                % been passed as a string, in which case it needs matching
                % up to the appropriate option
                if ischar(newVals{ii})
                    newVals{ii} = {newVals{ii}};
                end
                if iscell(newVals{ii}) && ischar(newVals{ii}{1})
                    % convert to the appropriate option
                    temp = cellfun(@(x)find(strcmpi(x,this.ChoiceStruct.Choices{ii}),1,'first'),newVals{ii}(:),'uni',false);
                    emptyinds = cellfun(@isempty,temp);
                    
                    temp(emptyinds) = repmat({NaN},[nnz(emptyinds),1]);
                    newVals{ii} = cell2mat(temp);
                end
                
                if isempty(newVals{ii})
                    % this need to be different for bioformat wells and
                    % fields - if they haven't been supplied, we need to
                    % use the value that was set previously
                    
                    % so only change to Inf for t, c, and z
                    newVals{ii} = Inf;
                end
                if any(~isfinite(newVals{ii}))
                    % there is a specific case that if an Inf has been sent
                    % for the isThumb (ie thumbnail) field, we don't want
                    % to return the image and the thumbnail
                    
                    if strcmpi(this.ChoiceStruct.Labels{ii},'isthumb')
                        newVals{ii} = 1;
                    else
                        % use the indices rather than the values?
% %                         newVals{ii} = this.ChoiceStruct.Choices{ii};
                        newVals{ii} = (1:numel(this.ChoiceStruct.Choices{ii}))';
                    end
                end
            end
            
        end
        function ChP = getChoiceGUI(this,parent)
            if nargin<2 % might want it to be empty at this point..
                parent = gfigure('Selection');
            end
            
            ChP = BlendSquareChoicesGUI(this.ChoiceStruct.Labels,this.ChoiceStruct.Choices,...
                [size(this.WellFieldMap,2),size(this.WellFieldMap,1)],'parent',parent);
        end
        function imObj = getSelectedImage(this,ChP)
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
            switch ChP.blendMode
                case 0
                    imObj = get2DObj(this,ChP);
                case 1
                    imObj = getC2DObj(this,ChP);
                case 2
                    imObj = get3DObj(this,ChP);
                case 3
                    imObj = getC3DObj(this,ChP);
                otherwise
                    error('Unknown mode, something''s gone wrong!')
            end
            
        end
        function imInfo = getSelectedInfo(this,ChP)
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
            
            if isa(ChP,'ChoicesGUI')
                imMode = ChP.blendMode;
            else
                imMode = 1;
            end
            
            switch imMode
                case 0
                    imInfo = get2DInfo(this,ChP);
                case 1
                    imInfo = getC2DInfo(this,ChP);
                case 2
                    imInfo = get3DInfo(this,ChP);
                case 3
                    imInfo = getC3DInfo(this,ChP);
                otherwise
                    error('Unknown mode, something''s gone wrong!')
            end
            
        end
        
        function imObj = getCurrentEmptyImage(this,ChP)
            
            zidx = strcmpi('zslice',this.ChoiceStruct.Labels);
            
           
            % what if there is no z?  Presumably it should be stored as
            % a 2DnC image instead?

            if nnz(zidx)>0 && numel(this.ChoiceStruct.Choices{zidx})>1
                imObj = getC3DObj(this,ChP);
            else
                imObj = getC2DObj(this,ChP);
            end
        end
        
        function aName = getTitle(this)
            aName = this.PlateName;
        end
        function labels = getChoiceLabels(this)
            labels = this.ChoiceStruct.Labels;
        end
        function labels = getShortLabels(this)
            labels = this.ChoiceStruct.ShortLabels;
        end
        
        
        
    end
    methods (Static)
        function parserObj = fromFolder(fol,fileext)
            % construct a parser object based on the first file found in
            % the folder that matches the extension.
% %             flist = dir(sprintf('%s/*.%s',fol,fileext));
% %             fileNames = {flist.name}';
            if isempty(strfind(fileext, '.'))
                fileNames = cmddir(['*.' fileext],fol,false);
            else
                fileNames = cmddir(['*' fileext],fol,false);
            end;
            
            if ~isempty(fileNames)
                parserObj = ParserBioFormats(fullfile(fol,fileNames{1}));
            else
                warning('No files found with matching extension')
                parserObj = [];
            end
            
        end
    end
end
