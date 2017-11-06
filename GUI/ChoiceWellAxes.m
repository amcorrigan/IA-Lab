classdef ChoiceWellAxes < WellAxes
    % Like LabelWellAxes but allows one and only one well to be selected
    
    properties
        current = [];
    end
    methods
        function obj = ChoiceWellAxes(current,grouplist,varargin)
            % initialize everything and then call the superclass
            % constructor when we've got everything
            
            grouplist(grouplist>2 | grouplist==1) = 2;
            
            if nargin<1 || isempty(current) || grouplist(current)==0
                current = find(grouplist>0,1,'first');
            end
            grouplist(current) = 1;
            
            obj = obj@WellAxes(grouplist,varargin{:});
            obj.current = current;
            
        end
        function clickfcn(obj,src,evt,clickind)
            % ensure that one well is selected at all times
            
            if ~isempty(clickind) && obj.groupData(clickind)>0
                obj.updateImIndex(obj.current,2);
                
                % colour blue
                obj.current = clickind;
                obj.updateImIndex(obj.current,1);
                drawnow()
                
                % need to convert back to row and column? maybe worth it?
                
                % Currently the event data required is a string denoting
                % the well ID, so construct that here
                
                cr = amcInd2Sub(obj.siz([2,1]),obj.current);
                wellstr = sprintf('%s%0.2d',char(64+cr(2)),cr(1));
                
                evtd = GenEvtData(wellstr);
                notify(obj,'choiceUpdate',evtd)

            end
            
        end
        
        function resetChoices(obj,current,grouplist)
            if nargin>2 && ~isempty(grouplist)
                grouplist(grouplist>2 | grouplist==1) = 2;
            
                obj.groupData = grouplist;
            end
            if nargin>1 && ~isempty(current)
                obj.current = current;
            end
            if obj.groupData(current)==0
                obj.current = find(obj.groupData>0,1,'first');
            end
            
            obj.groupData(obj.current) = 1;
            setImData(obj);
        end
        
% %         function set.Value(obj,val)
% %             
% %         end
% %         function get.Value(obj)
% %         
% %         end
    end
end
