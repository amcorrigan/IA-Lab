classdef ChoiceWellButtons < WellButtons
    properties
        Current;
    end
    methods
        function this = ChoiceWellButtons(current,grouplist,varargin)
            % keep the same inputs as ChoiceWellAxes during the transition
            
            grouplist(grouplist>1) = 2;
            
            if nargin<1 || isempty(current) || grouplist(current)<2
                current = find(grouplist>0,1,'first');
            end
            grouplist(current) = 3;
            
            this = this@WellButtons(grouplist,varargin{:});
            this.Current = current;
            
            
        end
        
        function clickfcn(this,src,evt,rowind,colind)
            % ensure that one well is selected at all times
            
            % the row and column headers are stored in the same grid as the
            % wells..
            % Therefore we need to calculate the correct indices for
            % determining which well has been clicked
            
            nonHeadInd = colind + (rowind-1)*this.Size(1);
            % this is the element of well-based arrays - ie the colours
            
            headInd = (colind+1) + rowind*(this.Size(1)+1);
            % this is the element of the GUI-based arrays - ie the button
            % handles
            
            % offset the current index to find which GUI element we need to
            % change
            currrc = amcInd2Sub(this.Size,this.Current);
            currHeadInd  = amcSub2Ind(this.Size+1,currrc+1);
            
            if ~isempty(nonHeadInd) && this.GroupData(nonHeadInd)>1
                % deselect the previously selected button
% %                 this.updateButtonStyle(this.Current,2)
                this.updateButtonStyle(currHeadInd,2)
                
                % colour the new selection appropriately
                this.Current = nonHeadInd;
                this.updateButtonStyle(headInd,3);
                drawnow() % makes the display appear a bit more responsive (rather than waiting until end of callback)
                
                % need to convert back to row and column? maybe worth it?
                
                % Currently the event data required is a string denoting
                % the well ID, so construct that here
                
                rc = amcInd2Sub(this.Size([1,2]),this.Current);
%                 wellstr = sprintf('%s%0.2d',char(64+cr(2)),cr(1));
                wellstr = rowcol2wellstr(rc(1),rc(2));
                
                evtd = GenEvtData(wellstr{1});
                notify(this,'choiceUpdate',evtd)

            end
            
        end
        
        function resetChoices(this,current,grouplist)
            if nargin>2 && ~isempty(grouplist)
                grouplist(grouplist>1) = 2;
            
                this.GroupData = grouplist;
            end
            if nargin>1 && ~isempty(current)
                this.Current = current;
            end
            if this.GroupData(current)<2
                this.Current = find(this.GroupData>1,1,'first');
            end
            
            this.GroupData(this.Current) = 3;
            this.setupDisplay();
        end
    end
end
