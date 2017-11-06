classdef IndexChoices < handle
    % interface for taking the possible options for image selection
    % (channel, z, time, xy, well, etc) and showing only those that are
    % relevant and, optionally, have more than one option.
    
    % The idea will be to allow an arbitrary set of labels to be specified,
    % and provide the tools to set, get and display these in a natural way
    
    % Instead of throwing errors when we try to set things outside the
    % allowed values, maybe events would be better? Then a GUI element can
    % listen for these
    
    % an update to this would be to allow vectors or multiple values to be
    % held simultaneously (like a multiple selection)
    
    % The data isn't consistently stored - if it's a range or free value,
    % the value itself is stored; if it's a choice from a finite range, the
    % index is stored instead.  The setting and getting takes care of all
    % of this though..
    
    % It would be possible to build a SetGet interface around this, but I
    % think the choices need to be set explicitly
    % an alternative might be to use subsref
    % This would preclude being able to put this class into an array, but
    % not likely to want to do that anyway..
    
    % maybe longnames could be reserved for a separate subclass
    
    % a further complication is that the value of one option could impact
    % on the choices available for another (for instance if different wells
    % have different z-stacks).  Something extra will be needed here to
    % somehow store the range of options available and update the
    % possibilities accordingly.
    
    properties (SetAccess = protected)
        labels
        
        longnames
        
        labelchoices
        % in order to be as general as possible if labelchoices{ii} is a cell
        % array or column vector, it represents discrete choices, whereas
        % if it is a two-element row vector, it means a continuous range,
        % and empty means anything
        
        labeltype
        
        values;
        
        
    end
    properties (SetAccess = protected, Hidden)
        % ready for using subsref to set properties using dot indexing
        methodNames
    end
    methods
        function obj = IndexChoices(labels,labelchoices,longnames,values)
            % a possible static method would be to take parameter value
            % pairs and parse them into this form.
            obj.labels = labels;
            
            if numel(labelchoices)~=numel(labels)
                error('Choices must have the same number of elements as labels')
            end
            obj.labelchoices = labelchoices;
            
            obj.doLabelType();
            
            if nargin<4 || isempty(values)
                obj.initialize();
            else
                obj.setAllValues(values);
            end
            
            if nargin<3 || isempty(longnames)
                longnames = labels;
            end
            if numel(longnames) ~= numel(labels)
                error('Longnames must have the same number of elements as labels')
            end
            obj.longnames = longnames;
        end
        
        function setAllValues(obj,valcell)
            % direct specification of values, through a struct or a cell
            % array
            args = {};
            if isstruct(valcell)
                fnames = fieldnames(valcell);
                
                for ii = 1:numel(fnames)
                    args = [args,{fnames{ii},valcell.(fnames{ii})}];
                end
            else
                if numel(valcell)~=numel(obj.labels)
                    error('Number of values doesn''t match the number of labels')
                end
                
                for ii = 1:numel(valcell)
                    args = [args,{obj.labels{ii},valcell{ii}}];
                end
            end
            set(obj,args{:});
        end
        
        function set(obj,varargin)
            % set the values using name parameter pairs
            
            count = 1;
            if ceil(numel(varargin)/2)~=(numel(varargin)/2)
                error('Inputs must be parameter-value pairs')
            end
            while count<numel(varargin)
                setSingle(obj,varargin{count},varargin{count+1});
                count = count + 2;
            end
        end
            
        function directSet(obj,labelIdx,valIdx)
            % direct setting of properties, for example through a GUI which
            % can then bypass the input checking
            for ii = 1:numel(labelIdx)
                obj.values{labelIdx(ii)} = valIdx(ii);
            end
        end
        
% %         function directGet(obj,labelIdx)
% %             
% %         end
        
        function setSingle(obj,labelstr,labelval)
            % check the chosen labelval against the allowed possibilities
            % try to be case insensitive like MATLAB's setget
            
            % then check the value against the type of the label
            % would an enum be better here?
            
            match = verifyMatch(obj,labelstr);
            
            switch obj.labeltype{match}
                case 'numeric'
                    if ~isnumeric(labelval)
                        error('Incorrect type of data')
                    end
                    valIdx = labelval==obj.labelchoices{match};
                    if nnz(valIdx)~=1
                        error('Value not in allowed range')
                    end
                    obj.values{match} = find(valIdx);
                case 'logical'
                    if ~islogical(labelVal)
                        error('Incorrect type of data')
                    end
                    
                    obj.values{match} = 1+double(labelval);
                case 'char'
                    if ~ischar(labelval)
                        error('Incorrect type of data')
                    end
                    valIdx = strcmpi(labelval,obj.labelchoices{match});
                    if nnz(valIdx)~=1
                        error('Value not in allowed range')
                    end
                    obj.values{match} = find(valIdx);
                case 'range'
                    if ~isnumeric(labelval)
                        error('Incorrect type of data')
                    end
                    if labelval<obj.labelchoices{match}(1) || labelval>obj.labelchoices{match}(2)
                        error('Value not in allowed range')
                    end
                    obj.values{match} = labelval;
                    
                case 'free'
                    if ~isnumeric(labelval)
                        error('Incorrect type of data')
                    end
                    obj.values{match} = labelval;
                otherwise
                    error('Shouldn''t be able to get here! Labeltypes shouldn''t be manually settable')
                    
            end
            
            
        end
        
        function value = get(obj,labelstr)
            match = verifyMatch(obj,labelstr);
            switch obj.labeltype{match}
                case {'numeric','logical'}
                    currval = obj.values{match};
                    if isfinite(currval)
                        value = obj.labelchoices{match}(obj.values{match});
                    else
                        value = currval;
                    end
                case 'char'
                    value = obj.labelchoices{match}{obj.values{match}};
                otherwise
                    value = obj.values{verifyMatch(obj,labelstr)};
            end
            
        end
        
        function flag = next(obj,labelstr)
            % if allowed, move to the next option
            match = verifyMatch(obj,labelstr);
            flag = 0;
            if any(strcmpi(obj.labeltype{match},{'range','free'}))
                error('Incorrect type of data')
            end
            
            % check the current value and move to the next
            % currently, the index isn't directly stored, but maybe it
            % should be?
            
        end
        function flag = prev(obj,labelstr)
            % if allowed, move to the next option
            match = verifyMatch(obj,labelstr);
            flag = 0;
            if any(strcmpi(obj.labeltype{match},{'range','free'}))
                error('Incorrect type of data')
            end
            
            % check the current value and move to the previous
            
        end
        
        function match = verifyMatch(obj,labelstr)
            if ischar(labelstr)
                match = strcmpi(labelstr,obj.labels);
                
            else
                match = false(numel(obj.labels),1);
                match(labelstr) = true;
            end
            if nnz(match)~=1
                error('Unknown or ambiguous label')
            end
        end
        
        function output = getChoices(obj,labelstr)
             match = verifyMatch(obj,labelstr);
             output = obj.labelchoices{match};
        end
        
        function output = getLabels(obj)
            output = obj.labels;
        end
        
        
        function doLabelType(obj)
            % determine the type automatically
            obj.labeltype = cell(numel(obj.labels),1);
            for ii = 1:numel(obj.labeltype)
                if isempty(obj.labelchoices{ii})
                    % can be anything
                    obj.labeltype{ii} = 'free';
                elseif iscell(obj.labelchoices{ii})
                    try
                    if all(cellfun(@isnumeric,obj.labelchoices))
                        obj.labeltype{ii} = 'numeric';
                    else
                        obj.labeltype{ii} = 'char';
                    end
                    catch ME
                        rethrow(ME)
                    end
                elseif ischar(obj.labelchoices{ii})
                    % only one choice of string
                    % shouldn't come up yet, but if we change the options
                    % outside the constructor
                    obj.labelchoices{ii} = obj.labelchoices(ii);
                    obj.labeltype{ii} = 'char';
                elseif isnumeric(obj.labelchoices{ii})
                    if all(size(obj.labelchoices{ii})==[1,2])
                        % two element row vector
                        obj.labelchoices{ii} = sort(obj.labelchoices{ii},'ascend');
                        obj.labeltype{ii} = 'range';
                    elseif size(obj.labelchoices{ii},2)==1
                        % column vector
%                         obj.labelchoices{ii} = mat2cell(obj.labelchoices{ii},ones(numel(obj.labelchoices{ii}),1));
                        
                        obj.labeltype{ii} = 'numeric';
                    else
                        error('Unknown label options')
                    end
                elseif islogical(obj.labelchoices{ii})
                    obj.labeltype{ii} = 'logical'; % for now, before replacing with TF
                else
                    error('Unknown label options')
                end
            end
        end
        
        function initialize(obj)
            % to begin with set to the first value in each case
            for ii = 1:numel(obj.labels)
                switch obj.labeltype{ii}
                    case {'numeric','char','logical'}
                        obj.values{ii} = 1;
                    case 'range'
                        obj.values{ii} = obj.labelchoices{ii}(1);
                    case 'free'
                        obj.values{ii} = 0;
                    otherwise
                       	error('Housekeeping, shouldn''t be able to get here!')
                end
            
            end
        end
        
        function s = toStruct(obj)
            args = {};
            for ii = 1:numel(obj.labels)
                if any(strcmpi(obj.labeltype{ii},{'logical','numeric'}))
                    args = [args,{obj.labels{ii}, obj.labelchoices{ii}(obj.values{ii})}];
                elseif strcmpi(obj.labeltype{ii},'char')
                    args = [args,{obj.labels{ii}, obj.labelchoices{ii}{obj.values{ii}}}];
                else
                    args = [args,{obj.labels{ii}, obj.values{ii}}];
                end
            end
            s = struct(args{:});
        end
    end
end