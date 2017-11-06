classdef ParserMultiPlate < ImgLoader
    properties
        ParserArray = {}
        ChannelLabels
    end
    methods
        function this = ParserMultiPlate(parsers)
            if nargin>0 && ~isempty(parsers)
                for ii = 1:numel(parsers)
                    this.addParser(parsers(ii));
                end
            end
        end
        
        function addParser(this,parser,newName)
            if nargin<2 || isempty(parser)
                return
            end
            % allow a new name to be given to the parser.
            % This is useful for when the parsers are from files in the
            % same folder, and so might be given the same name when
            % generated automatically.
            
            doCheck = isempty(this.ParserArray);
            
            
            if ~iscell(parser)
                parser = {parser};
            end
            if nargin>2 && ~isempty(newName)
                if ~iscell(newName)
                    newName = {newName};
                end
                for ii = 1:numel(newName)
                    parser{ii}.PlateName = newName{ii};
                end
            end
            
            this.ParserArray = [this.ParserArray;parser(:)];
            
            
            if doCheck && ~isempty(this.ParserArray)
                this.ChannelLabels = this.ParserArray{1}.ChannelLabels;
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
                imMode = 3;
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
            newVals = getValuesFromInputs(this,varargin{:});
            
            plateInd = newVals{1};
            % this is an integer
            
            imInfo = this.ParserArray{plateInd}.getSelectedInfo(newVals(2:end));
            imInfo.PlateID = this.ParserArray{plateInd}.PlateName;
        end
        
        function imObj = get2DObj(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            imObj = this.ParserArray{newVals{1}}.get2DObj(newVals(2:end));
            
            % prefix the tag with the current plate name
            imObj = this.addPlateToTag(imObj,this.ParserArray{newVals{1}}.PlateName);
        end
        function imObj = get3DObj(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            imObj = this.ParserArray{newVals{1}}.get3DObj(newVals(2:end));
            
            % prefix the tag with the current plate name
            imObj = this.addPlateToTag(imObj,this.ParserArray{newVals{1}}.PlateName);
        end
        function imObj = getC2DObj(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            imObj = this.ParserArray{newVals{1}}.getC2DObj(newVals(2:end));
            
            % prefix the tag with the current plate name
            imObj = this.addPlateToTag(imObj,this.ParserArray{newVals{1}}.PlateName);
        end
        function imObj = getC3DObj(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            imObj = this.ParserArray{newVals{1}}.getC3DObj(newVals(2:end));
            
            % prefix the tag with the current plate name
            imObj = this.addPlateToTag(imObj,this.ParserArray{newVals{1}}.PlateName);
        end
        function imObj = getAC2DObj(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            imObj = this.ParserArray{newVals{1}}.getAC2DObj(newVals(2:end));
            
            % prefix the tag with the current plate name
            imObj = this.addPlateToTag(imObj,this.ParserArray{newVals{1}}.PlateName);
        end
        function imObj = getAC3DObj(this,varargin)
            newVals = getValuesFromInputs(this,varargin{:});
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            imObj = this.ParserArray{newVals{1}}.getAC3DObj(newVals(2:end));
            
            % prefix the tag with the current plate name
            imObj = this.addPlateToTag(imObj,this.ParserArray{newVals{1}}.PlateName);
        end
        function emptyObj = getCurrentEmptyImage(this,ChP)
            newVals = getValuesFromInputs(this,ChP);
            
            % the first value is the choice of parser object, then the rest
            % can be passed directly on
            emptyObj = this.ParserArray{newVals{1}}.getCurrentEmptyImage(ChP.CurrGUI);
            
            % prefix the tag with the current plate name
            emptyObj = this.addPlateToTag(emptyObj,this.ParserArray{newVals{1}}.PlateName);
        end
        
        function newVals = getValuesFromInputs(this,varargin)
            args = varargin; % is this necessary?
            
            if numel(args)==1
                if isa(args{1},'ChoicesGUI')
                    newVals = getCurrentValues(args{1});
                elseif ~iscell(args{1})
                    newVals = num2cell(args{1}(:)');
                else
                    newVals = args{1};
                end
            else
                % need to find the plate first and remove it from the list
                % of inputs
                
                ind = find(strcmpi('plate',args)|strcmpi('plateid',args),1,'first');
                if isempty(ind)
                    error('plate information not found')
                end
                
                plateval = args{ind+1};
                args(ind:ind+1) = [];
                
                if ischar(plateval)
                    % need to compare with the plate names to see which one
                    % we're after
                    platenames = cellfun(@(x)x.PlateName,this.ParserArray,'uni',false);
                    plateval = find(strcmpi(plateval,platenames),1,'first');
                    if isempty(plateval)
                        % just return the first for now, but this isn't the
                        % best option
                        plateval = 1;
                    end
                end
                
                outVals = this.ParserArray{plateval}.getValuesFromInputs(args{:});
                
                newVals = [plateval,outVals];
            end
        end
        
        function ChP = getChoiceGUI(this,parent)
            if nargin<2 % might want it to be empty at this point..
                parent = gfigure('Selection');
            end
            
            ChP = MultiPlateGUI(parent,this.ParserArray);
            
        end
        
        function str = getTitle(this)
            str = 'Multiple plates';
        end
        
        function batchParser = getBatchParser(this,imType)
            % try to determine the type of each one within the multi
            % throughput class
            % it's currently called ThroughputMultiIX because IX is the
            % main one for which it's implemented, although this should
            % probably be changed
            if nargin<2 || isempty(imType)
                imType = '3DnC';
            end

            % check what type the first parser is and base the decision on
            % that
            if isa(this.ParserArray{1},'ParserXpress')
                batchParser = ThroughputMultiIX(this,imType);
            else
                batchParser = ThroughputMulti(this);
%                 error('Batch parser not completed for this type of parser')
            end
        end
        
        function labels = getChoiceLabels(this)
            % this could go awry if we've passed different types of parser
            % into this multiplate object
            
            labels = [{'PlateID'},this.ParserArray{1}.ChoiceStruct.Labels];
            
        end
        
        function labels = getShortLabels(this)
            % this could go awry if we've passed different types of parser
            % into this multiplate object
            
            labels = [{'pl'},this.ParserArray{1}.ChoiceStruct.ShortLabels];
            
        end
        
        
    end
    
    methods (Static)
        function imobjs = addPlateToTag(imobjs,platename)
            % put the platename at the start of each tag
            for ii = 1:numel(imobjs)
                imobjs{ii}.Tag = [platename, ' - ', imobjs{ii}.Tag];
            end
        end
        function multiObj = ix(folders,varargin)
            % generate the imageXpress parsers and put them into a multi
            % plate parser
            multiObj = ParserMultiPlate();
            for ii = 1:numel(folders)
                try
                    multiObj.addParser(ParserXpress(folders{ii},varargin{:}));
                catch ME
                    fprintf('Problem found with folder %d\nError:\n%s\n',...
                        ii,getReport(ME))
                end
            end
        end
        
        function multiObj = yokogawa(folders)
            multiObj = ParserMultiPlate();
            for ii = 1:numel(folders)
                try
                    multiObj.addParser(ParserYokogawa(folders{ii}));
                catch ME
                    fprintf('Problem found with folder %d\nError:\n%s\n',...
                        ii,getReport(ME))
                end
            end
        end
    end
end
