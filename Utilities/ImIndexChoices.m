classdef ImIndexChoices < IndexChoices
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
        shortlabels
    end
    
    methods
        function obj = ImIndexChoices(labels,labelchoices,longnames,values,shortlabels)
            % a possible static method would be to take parameter value
            % pairs and parse them into this form.
            if nargin<4
                values = [];
            end
            if nargin<3
                longnames = [];
            end
            obj = obj@IndexChoices(labels,labelchoices,longnames,values);
            
            if nargin<5 || isempty(shortlabels)
                shortlabels = labels;
            end
            obj.shortlabels = shortlabels;
        end
        
        function setSingle(obj,labelstr,labelval)
            % check the chosen labelval against the allowed possibilities
            % try to be case insensitive like MATLAB's setget
            
            % then check the value against the type of the label
            % would an enum be better here?
            try
            match = verifyMatch(obj,labelstr);
            catch ME
                rethrow(ME)
            end
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
        
        function match = verifyMatch(obj,labelstr)
            
            if ischar(labelstr)
                
                match = strcmpi(labelstr,obj.shortlabels) | strcmpi(labelstr,obj.labels);
                
            else
                match = false(numel(obj.labels),1);
                match(labelstr) = true;
            end
            if nnz(match)~=1
                error('Unknown or ambiguous label')
            end
        end
        
    end
end