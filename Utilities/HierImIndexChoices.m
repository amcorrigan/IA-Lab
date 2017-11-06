classdef HierImIndexChoices < ImIndexChoices
    % these names are getting ridiculously long now..
    % Hierarchical IndexChoices for image data
    
    properties (SetAccess = protected, Hidden)
        M % the availability matrix, which for this case can be T/F
        fullsiz % store this too, rather than calculating each time
        
        avChoices_ % property returned when the containing panel asks availChoices
        % this can be numerical indices of the full range of choices
        avRelInd_
        
        % properties inherited from superclasses, as a reminder
        % labels
        % longnames
        % labelchoices
        % labeltype - not really used that much
        % values
        % shortlabels
        
    end
    
    events
        availUpdate % notify the containing ImListPanel that the choices have been updated
    end
    methods
        function obj = HierImIndexChoices(labels,labelchoices,longnames,values,shortlabels,M)
            obj = obj@ImIndexChoices(labels,labelchoices,longnames,values,shortlabels);
            obj.M = M>0;
            
            obj.fullsiz = size(obj.M); % should correspond to the full number of
            % choices at each level.
            
            % then go through the options to make sure we're set to a valid
            % choice, by setting the first value to what it is currently
            obj.avChoices_ = cell(numel(obj.labels),1);
            obj.avChoices_{1} = (1:numel(obj.labelchoices{1}))'; % top level always has full choice
            
            obj.avRelInd_ = zeros(numel(obj.labels),1);
            obj.avRelInd_(1) = obj.values{1};
            
            obj.directSet(1,obj.values{1});
            
        end
        
        function directSet(obj,labelIdx,valIdx,noEvent)
            % rather than being recursive, loop through all lower labels in
            % this method
            
            % valIdx is the index of the currently available choices, so it
            % only has to be less than the number of elements
            if nargin<4 || isempty(noEvent)
                noEvent = false;
            end
            
            if valIdx > numel(obj.avChoices_{labelIdx})
                error('Index not available for selection')
            else
                realIdx = obj.avChoices_{labelIdx}(valIdx);
            end
            
            % multiple updates aren't necessarily allowed, since the
            % indices may jump around during a previous update
            obj.values{labelIdx} = realIdx;
            obj.avRelInd_(labelIdx) = valIdx;
            
            % then update the choices for the next level down
            for idx = (labelIdx+1):numel(obj.labels)
                obj.avChoices_{idx} = hierAllowedChoices(obj,idx);
                
                % check if the current value is allowed, and if not, change
                % it
                % Currently set to the first available for simplicity, but
                % could change to be the nearest available instead
                relInd = find(obj.values{idx}==obj.avChoices_{idx});
                if isempty(relInd)
                    relInd = 1;
                    
                end
                
                obj.values{idx} = obj.avChoices_{idx}(relInd);
                obj.avRelInd_(idx) = relInd; % need to know this for updating the GUI
            end
            
            % at the end, trigger an availUpdate event, so that the
            % listening object can update the options and values, and
            % choose whether to update the image
            if ~noEvent
                notify(obj,'availUpdate');
            end
        end
        
        function allowedInds = hierAllowedChoices(obj,idx)
            % idx is the level for which we're getting the allowed choices,
            % not the level which has just been modified
            % so it should always be 2 or greater, never 1!
            if idx==1
                error('This should never happen!')
            end
            
            try
            vals = cell2mat(obj.values);
            catch ME
                rethrow(ME)
            end
            
            
            ind = amcSub2Ind(obj.fullsiz(1:(idx-1)),vals(1:(idx-1)));
            T = joinDimensions(obj.M,{(1:idx-1),idx}); % the rest of the dimensions are joined implicitly
            A = any(T(ind,:,:),3);
            % A is a logical row vector denoting which options are
            % available
            % we want to return a set of indices
            allowedInds = find(A);
        end
        
        
        function set(obj,varargin)
            % set the values using name parameter pairs
            
            count = 1;
            noEvent = false;
            if nargin>1 && strcmpi(varargin{1},'silent')
                noEvent = true;
                count = count + 1;
            end
            while count<numel(varargin)
                setSingle(obj,varargin{count},varargin{count+1},noEvent);
                count = count + 2;
            end
        end
           
        function setSingle(obj,labelstr,labelval,noEvent)
            % override this method, now that there is a clear hierarchy
            % both setSingle and directSet need to be sent through the same
            % process
            
            % this needs to check against the currently available choices,
            % not the whole lot
            
            if nargin<4 || isempty(noEvent)
                noEvent = false;
            end
            
            ind = find(verifyMatch(obj,labelstr));
            
            switch obj.labeltype{ind}
                case 'numeric'
                    if ~isnumeric(labelval)
                        error('Incorrect type of data')
                    end
                    valIdx = find(labelval==obj.labelchoices{ind});
                    availIdx = find(valIdx==obj.avChoices_{ind});
                    if nnz(availIdx)~=1
                        error('Value not in allowed range')
                    end
                    obj.values{ind} = valIdx;
                case 'logical'
                    if ~islogical(labelVal)
                        error('Incorrect type of data')
                    end
                    
                    valIdx = 1+double(labelval);
                    availIdx = find(valIdx==obj.avChoices_{ind});
                    if nnz(availIdx)~=1
                        error('Value not in allowed range')
                    end
                case 'char'
                    if ~ischar(labelval)
                        error('Incorrect type of data')
                    end
                    valIdx = find(strcmpi(labelval,obj.labelchoices{ind}));
                    try
                    availIdx = find(valIdx==obj.avChoices_{ind});
                    catch ME
                        rethrow(ME)
                    end
                    if nnz(availIdx)~=1
                        error('Value not in allowed range')
                    end
                    
                case 'range'
                    error('This type of data isn''t allowed in a hierarchical index choices object')
                case 'free'
                    if ~isnumeric(labelval)
                        error('Incorrect type of data')
                    end
                otherwise
                    error('Shouldn''t be able to get here! Labeltypes shouldn''t be manually settable')
            
            end
            
            directSet(obj,ind,availIdx,noEvent);
        end
        
        
        function newfrag = updateChoices(obj,val,Mfrag)
            % check what options are available for the tree up to this
            % point
            siz = size(Mfrag);
            newfrag = reshape(Mfrag(val,:),siz(2:end));
            
            
        end
        
        function [aChoices,aRelInd] = availChoices(obj,labelstr)
            % return the available choices for each option, which depends
            % on the current value of it's parent
            
            
            if nargin<2 || isempty(labelstr)
                aChoices = obj.avChoices_;
                aRelInd = obj.avRelInd_;
            else
                ind = find(verifyMatch(obj,labelstr));
                
                aChoices = obj.avChoices_{ind};
                aRelInd = obj.avRelInd_(ind);
            end
        end
    end
end