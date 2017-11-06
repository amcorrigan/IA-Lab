classdef BlendSquareChoicesGUI < ChoicesGUI
    properties
        MainVBox
        Labels
        PlateDimensions
        
        hb
        uiArray
        
        panelWidth
        hasWell = false;
        WellChoices
        
        wellLstn % listener for the well choice being changed
        
        panelHeight = 300;

        % additional properties required
        blh % handle to blend BoxPanel
        allToggleArray % handles to the tickboxes
            
        LoadButton
        ButtonBox
    end
    properties (Dependent)
        blendMode
    end
    
    methods
        function this = BlendSquareChoicesGUI(labels,choices,platesiz,varargin)
            
            this.MainVBox = uix.VBox(varargin{:});
            this.Labels = labels;
            
            this.hb = uix.HBox('parent',this.MainVBox);
            
            count = 0;
            this.panelWidth = [];
            
            % find out which is the last label?
            
            for ii = 1:numel(labels)
                
                if strcmpi(labels{ii},'well')
                    % in this case, put the wellselector directly in
                    % the invisVbox.  Need to find an easy way of
                    % moving this above the hb
                    
                    % put in a BoxPanel for clarity
                    tempbox = uix.BoxPanel('parent',this.MainVBox,'Title','Well Selection');
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Newly inserted to use the new well browser
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Newly inserted to use the new well browser
                    s = cell2mat(regexp(choices{ii},'(?<row>[A-Z])(?<col>\d{1,2})','names'));
                    r = double(upper([s.row]))'-64;
                    c = arrayfun(@(x)str2double(x.col),s);
                    this.WellChoices = choices{ii};
                    
                    this.PlateDimensions = platesiz; % siz should now be passed in the inputs
% % %                     present = amcSub2Ind(this.PlateDimensions,[c,r]);
                    present = amcSub2Ind(this.PlateDimensions([2,1]),[r,c]);
                    grouplist = ones(prod(this.PlateDimensions),1);
                    grouplist(present) = 2;
                    
                    current = present(1);
                    
% % %                     this.uiArray{ii} = ChoiceWellAxes(current,grouplist,this.PlateDimensions([2,1]),tempbox);
                    this.uiArray{ii} = ChoiceWellButtons(current,grouplist,this.PlateDimensions([2,1]),tempbox);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    
                    this.wellLstn = addlistener(this.uiArray{ii},'choiceUpdate',@this.wellcallback);
                    
                    this.panelWidth = 400;
                    this.hasWell = true;
                else
                    
                    % put in a BoxPanel for clarity
                    tempbox = uix.BoxPanel('parent',this.hb,'Title',labels{ii});
                            
                    tempvb = uix.VBox('parent',tempbox);
                    
                    % they should all be the same
                    
                    this.uiArray{ii} = uicontrol('style','listbox','parent',tempvb,...
                        'max',2,'min',0,'callback',{@this.clickcallback,ii,'list'},...
                        'string',arrayfun(@num2str,choices{ii},'uni',false),'value',1);
                    
%                     if any(strcmpi(labels{ii},{'timepoint','channel','zslice'}))
                    if any(strcmpi(labels{ii},{'channel','zslice'}))
                        this.allToggleArray{ii} = uicontrol('Style','ToggleButton','Value',false,...
                              'parent',tempvb,'callback',{@this.clickcallback,ii,'button'},'String',...
                              'Show all','backgroundcolor',[0.93,0.93,0.93]);
                    end
                    
                end
                
                    
            end
            this.LoadButton = uicontrol('Style','PushButton',...
                'parent',tempvb,'callback',@(src,evt)notify(this,'choiceUpdate'),...
                'String','Load Image','backgroundcolor',[0.93,0.93,0.93]);
            temphh = get(tempvb,'heights');
            temphh(end) = 40;
            set(tempvb,'heights',temphh)

            this.ButtonBox = tempvb;
                
            
            if isempty(this.panelWidth)
                this.panelWidth = max(200,50*count);
            end
            
            % rearrange the order here so that the well appears at the top
            if this.hasWell
                set(this.hb,'parent',[])
                set(this.hb,'parent',this.MainVBox)
%                 set(this,'Children',flipud(get(this,'Children')))
                set(this.MainVBox,'Heights',[-1.6,-1]);
            end
            
            
            % at the end, setup the mode to be what we want
            zidx = find(strcmpi(this.Labels,'zslice'));
            if ~isempty(zidx) && numel(choices{zidx})>1
                this.clickcallback([],[],zidx,'all');
            end
            
            cidx = find(strcmpi(this.Labels,'channel'));
            if ~isempty(cidx)
                this.clickcallback([],[],cidx,'all');
            end
            
            
            
        end
        
        function clickcallback(this,src,evt,labelidx,clicktype)
            % do the very generic stuff here, so that it can be called first by the more
            % complex cases
            if strcmpi(clicktype,'list')
                % clicked a specific value
                if isa(this.allToggleArray{labelidx},'matlab.ui.control.UIControl')
                    set(this.allToggleArray{labelidx},'Value',0,'backgroundcolor',[0.93,0.93,0.93])
                end
                    

            else
                % clicked the 'all' button
                if isa(this.allToggleArray{labelidx},'matlab.ui.control.UIControl')
                    set(this.allToggleArray{labelidx},'Value',1,'backgroundcolor',[0.4,0.4,0.7])
                    
                    
                end
                
                set(this.uiArray{labelidx},'Value',[])

            end
            
        end
        
        function wellcallback(this,src,evtd)
% %             % the well selector has been changed
% %             
% %             % the well string is contained in the eventdata
% %             wellstr = evtd.data;
% %             if isempty(wellstr)
% %                 % need to change the well selection back to the current
% %                 % choice
% %                 setSelection(src,get(this.IC,'well'));
% %             else
% %                 % should really get the ind value from IC rather than the
% %                 % GUI
% %                 ind = find(cellfun(@(x)isa(x,'ChoiceWellButtons'),this.uiArray));
% %                 
% %                 newidx = find(strcmpi(wellstr,this.IC.labelchoices{ind}));
% %                 if ~isa(this.uiArray{ind},'ChoiceWellButtons')
% %                     set(this.uiArray{ind},'Value',newidx)
% %                 end
% %                 
% %             end
            
        end
        
        function currVals = getCurrentValues(this)
            % return a cell array of the current choices, replacing any
            % 'all' options with the current range of values
            
            wellidx = strcmpi('well',this.Labels);
            
            rc = amcInd2Sub(this.uiArray{wellidx}.Size,this.uiArray{wellidx}.Current);
            
            wellstr = rowcol2wellstr(rc(1,1),rc(1,2));
            
            wellind = find(strcmpi(wellstr,this.WellChoices));
            
            currVals = cell(1,numel(this.Labels));
            currVals{wellidx} = wellind;
            currVals(~wellidx) = cellfun(@(x)get(x,'value'),this.uiArray(~wellidx),'uni',false);
            
            currVals(cellfun(@isempty,currVals)) = repmat({Inf},[1,nnz(cellfun(@isempty,currVals))]);
            
            
        end
        
        function val = get.blendMode(this)
            % get the current blendmode based on which toggle buttons are
            % selected
            
            zidx = strcmpi('zslice',this.Labels);
            cidx = strcmpi('channel',this.Labels);
            
            zval = get(this.allToggleArray{zidx},'Value');
            cval = get(this.allToggleArray{cidx},'value');
            
            val = cval + 2*zval;
            
        end
        
        function delete(this)
            % this should clean up the display
            delete(this.MainVBox)
            
%             disp('Hello, working')
        end
    end
end
