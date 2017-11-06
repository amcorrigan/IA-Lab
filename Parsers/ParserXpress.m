classdef ParserXpress < ParserHCB
    % Parser for ImageXpress experiments
    %
    % This has a lot in common with the yokogawa parser, and so a lot of
    % the general code is contained in the ParserHCB class
    % The main part that Xpress experiments have that CV7000 and others
    % don't is the presence of thumbnail images already.
    properties
        
    end
    methods
        function this = ParserXpress(plateDir,channelColours,imnames)
            if nargin<1 || isempty(plateDir)
                plateDir = cd;
            end
            
            platePath = az_getDeepestChildFolderName(plateDir);
            if isempty(platePath)
                platePath = plateDir;
            end
            platePath = syspath(platePath);
            
            % store the plate name too for convenience, although perhaps a
            % method would work just as well?
            [~,plName] = fileparts(platePath);
            
            % allow imnames to be supplied directly during the debugging
            % process
            if nargin<3 || isempty(imnames)
                if ispc
                    cmdArray = sprintf('dir \"%s\\*.tif\" /b /a-d', platePath);
                    [~, fileNames] = dos(cmdArray);

                    % fix for a warning message that comes up when dir is called
                    % from a network location
                    newlineInds = strfind(fileNames,sprintf('\n'));

                    ind1 = [1;newlineInds(1:end-1)'+1];
                    ind2 = newlineInds'-1;
                    imnames = arrayfun(@(x,y) fileNames(x:y),ind1,ind2,'uni',false);
                    
                    if any(strcmpi(imnames,'UNC paths are not supported.  Defaulting to Windows directory.'))
                        % the first three rows need removing
                        imnames = imnames(4:end);
                    end
                    
                    if any(strcmpi(imnames,'File Not Found'))
                        error('No images found (.tif extension)')
                    end

                else
                    imnames = amcFullDir('*.tif',0,platePath);
                end
            end
            
            X = ParserXpress.name2props(imnames);
            % might want some way of ignoring the thumbnails for the GUI
            % part - but still be able to read them programmatically?
            
            [M,idx,choices,labels] = ParserXpress.existmat(X);
            
            this.ChoiceStruct.ImMap = M;
            this.ChoiceStruct.Labels = labels;
            this.ChoiceStruct.Choices = choices;
            this.ChoiceStruct.ShortLabels = {'w','s','c','n'}';
            this.ImIndex = idx; % Map and Idx are mirrors of each other for going forward and backward
            this.ImNames = imnames;
            this.PlateName = plName;
            this.PlatePath = platePath;
            
            
            % sort out the colour of each channel
            if nargin<2
                channelColours = {};
            end
            
            numchan = this.getTotalNumChan();
            
            if numchan==1
                % set to white if only one channel
                colourcycle = [1,1,1];
            else
                % otherwise assume that DAPI is first, followed by green
                colourcycle = [0,0,1;0,1,0;1,0,0;1,1,1;1,1,0;0,1,1;1,0,1];
            end
            
            defaultColours = num2cell(colourcycle(mod((1:numchan)-1,size(colourcycle,1))+1,:),2);
            
            if numel(channelColours)<numchan
                channelColours((numel(channelColours)+1):numchan) = ...
                    defaultColours((numel(channelColours)+1):numchan);
            end
            
            this.NativeColours = channelColours(:);
            this.ChannelLabels = arrayfun(@num2str,(1:numel(this.NativeColours))','uni',false);
            
            this.setPlateDimensions();
            this.detectImsiz();
        end
        
        function setPlateDimensions(this)
            % no metadata file, have to guess the plate dimensions from the
            % possible well locations
            
            [r,c] = wellstr2rowcol(this.ChoiceStruct.Choices{1});
            
            maxc = max(c);
            maxr = max(r);
            % 4 well is 1x4
            % 6 well is 2x3
            % 24 well is 4x6
            % 96 well is 8x12
            % 384 is 16x24
            % 1536 is 32x48
            if maxr==1 && maxc<=4
                % guess at 4 well dish
                cdim = 4;
                rdim = 1;
            else
                % explicit cases would probably be easier than this...
                cind = max(0,ceil(log2((maxc)/3)));
                rind = max(0,ceil(log2(maxr/2)));
                
                useind = max(cind,rind);
                
                cdim = 3*2^useind;
                rdim = 2*2^useind;
            end
            
            this.PlateDimensions = [cdim,rdim];
            
        end
        
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
            
            hasthumb = false;
            thumbidx = find(strcmpi('isthumb',this.ChoiceStruct.Labels));
            if ~isempty(thumbidx)
                joinorder = [joinorder,{thumbidx}];
                hasthumb = true;
            end
            
            S = joinDimensions(this.ChoiceStruct.ImMap,joinorder);
            % the function above permutes and reshapes so that the new
            % order is well, channel, zslice, then everything else
            % in 1 dimension
            
            if ~isempty(thumbidx)
                % choose the thumbnail image if possible
                if ~isempty(zidx)
                    S = S(:,:,:,end,1);
                else
                    S = S(:,:,end,1);
                end
            end
            if ~isempty(zidx)
                % Choose the middle z-slice
                S = ordChoice(S,0.5,3); % 50%, 3rd dimension
            end
            
            progressBarAPI('finish');
            progressBarAPI('init','Creating plate view',nnz(S));
            
            [wellRow, wellCol] = wellstr2rowcol(this.ChoiceStruct.Choices{1});
            
            for i = 1:size(S, 1)
                addtext = false;
                
                for j = 1:size(S, 2)

                    if S(i, j)==0
                        continue;
                    end


                    imFileName = fullfile(this.PlatePath, this.ImNames{S(i,j)});
                    
                    if ~hasthumb
                        aThumbnail = imresize(imread(imFileName, ...
                                         'PixelRegion', {[1 10 this.ImSize(1)],[1 10 this.ImSize(2)]}),...
                                         [H W]);
                    else
                        aThumbnail = imresize(imread(imFileName),[H,W]);
                    end

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
            
            revisedColour = this.NativeColours(:);
            
            thumbObj = cImage2DnC([], [],[revisedColour;{[0.99,0.99,0.99]}], [(1:size(thumbnailImage,3))';NaN],...
                [this.PixelSize*20, this.PixelSize*20], 'Plate',...
                [squeeze(num2cell(thumbnailImage,[1, 2]));{textImage}]);            
            
            progressBarAPI('finish');
        end
        
        
        function ChP = getChoiceGUI(this,parent)
            if nargin<2 % might want it to be empty at this point..
                parent = gfigure('Selection');
            end
            % the preferred display style for CV7000 experiments
            % ChP = BlendListPanelPlusWell(this.IC,'parent',parent);
            ChP = BlendChoicesGUI(BlendHierImIC(this.ChoiceStruct.Labels,this.ChoiceStruct.Choices,...
                [],[],this.ChoiceStruct.ShortLabels,this.ChoiceStruct.ImMap>0),this.PlateDimensions,'parent',parent);
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
                imMode = 1;
            end
            
            switch imMode
                case 0
                    imInfo = get2DInfo(this,varargin{:});
                case 1
                    imInfo = getC2DInfo(this,varargin{:});
                case 2
                    imInfo = get3DInfo(this,varargin{:});
                case 3
                    imInfo = getC3DInfo(this,varargin{:});
                otherwise
                    error('Unknown mode, something''s gone wrong!')
            end
            
        end
        
    end
    methods (Static)
        
        function X = name2props(imnames)
            % take a filename and return the properties, such as Channel,
            % well, etc.
            % Currently it looks like the order is always the same, but try
            % to arrange so that it doesn't matter
            
            % Side note - if the order IS fixed, a single regex could
            % extract everything we need, rather than one for each property
            % this will also help if w isn't always the last property
            
            % thumbnail - store as TF
            s0 = regexp(imnames,'_thumb');
            
            % can't assume that there'll be an underscore after any of
            % these tags
            
            % well ID - store as string
            s1 = regexp(imnames,'_(?<well>[A-Z]\d{2})','names');
            
            % site (XY) - store as number
            s2 = regexp(imnames,'_s(?<site>\d+)','names');
            
            % channel - store as number
            s3 = regexp(imnames,'_w(?<channel>\d{1})','names');
            
            % store using shortcuts, and have long names added separately
            
            % each of these tags (except _thumb) should be found in all
            % images or none at all, rather than some and not others
            wellind = cellfun(@(x)ParserXpress.ternary(isempty(x),'',x.well),s1,'uniformoutput',false);
            siteind = cellfun(@(x)ParserXpress.ternary(isempty(x),NaN,amcstr2double(x.site)),s2,'uniformoutput',false);
            chanind = cellfun(@(x)ParserXpress.ternary(isempty(x),NaN,amcstr2double(x.channel)),s3,'uniformoutput',false);
            thumbind = cellfun(@(x)~isempty(x),s0,'UniformOutput',false);
            
            % check for if all of these are NaNs, and if they are, replace
            % them with ones instead
            if all(arrayfun(@(x)isempty(x{1}),wellind))
                % no well information, replace them all with 'A01'
                wellind = repmat({'A01'},[numel(wellind),1]);
            end
            
            if all(arrayfun(@(x)isnan(x{1}),siteind))
                % no site information, make them all 1
                siteind = num2cell(ones(numel(siteind),1),2);
            end
            
            if all(arrayfun(@(x)isnan(x{1}),chanind))
                % no channel information, make them all 1
                chanind = num2cell(ones(numel(chanind),1),2);
            end
            
            X = struct('well',wellind ,'site',siteind,'channel',chanind,'isThumb',thumbind);
        end
        
        function [M,idx,choices,labels] = existmat(X)
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
        
        function cvobj = browseForFile()
            
            %___________________________________________
            %   To select all the sub dirs
            platesDir = uigetdir('', 'Please select the folder which contains the plate(s).');

            if isequal(platesDir, 0)
                msgbox('Please indicate the location of plates.', 'Error', 'warn');
                cvobj = [];
                return;
            end;
            
            % check if there are multiple folders inside the chosen folder
            alldirs = findChildFolders(platesDir);
            
            if numel(alldirs)==1
                cvobj = ParserXpress(alldirs{1});
            else
                cvobj = ParserMultiPlate.ix(alldirs);
            end
        end
        function cvobj = browseForFolder()
            cvobj = ParserXpress.browseForFile();
        end
        
        function output = ternary(cond,trueval,falseval)
            % MATLAB version of ternary operator, for inlining into functions like
            % cellfun or arrayfun without having to create extra functions.

            % this might not work fully, because the idea behind the ternary operator is that
            % falseval is only checked for being able to be evaluated if the condition
            % is failed, whereas here it must not cause any errors

            if cond
                output = trueval;
            else
                output = falseval;
            end       
        end
    end
    
end