classdef ActionBlendChoicesGUI < ChoicesGUI
    properties
        MainVBox
        IC
        PlateDimensions
        
        hb
        uiArray
%         valhArray
        showUnique = true;
        
        panelWidth
        hasWell = false;
        
        hierLstn % listener for the choices being updated by a hierarchical choices object
        % should this be a separate sub-class?
        wellLstn % listener for the well choice being changed
        
        panelHeight = 300;

        % additional properties required
        blh % handle to blend BoxPanel
        allToggleArray % handles to the tickboxes

        blendMode = 0;

        chanidx
        zidx % shortcuts to the appropriate indices
        actidx
        
        % LoadTriggers can potentially be changed by the user depending on
        % preference
% %         LoadTriggers = {'channel','zslice'};
% %         LoadTriggers = {'zslice'};
        LoadTriggers = {}; % With a dedicated load button, no need for this
        LoadButton
        ButtonBox % new part of the ChoicesGUI interface which will allow QC and other elements to be added
    end
    
    methods
        function this = ActionBlendChoicesGUI(IC,plateSize,varargin)
            
            this.MainVBox = uix.VBoxFlex('spacing',5,varargin{:});
            
            this.IC = IC;
            
            % the choices should already be set to something possible
            this.hierLstn = addlistener(this.IC,'availUpdate',@this.availChange);
            
            this.hb = uix.HBox('parent',this.MainVBox);
            
            count = 0;
            this.panelWidth = [];
            
            % find out which is the last label?
            
            this.uiArray = cell(numel(this.IC.labels),1);
            this.allToggleArray = cell(numel(this.IC.labels),1);
            
            for ii = 1:numel(this.IC.labels)
                if ~this.showUnique && numel(this.IC.labelchoices{ii})==1
                    this.uiArray{ii} = [];
                    continue
                end
                
                if strcmpi(this.IC.labels{ii},'well')
                    % in this case, put the wellselector directly in
                    % the invisVbox.  Need to find an easy way of
                    % moving this above the hb
%                     this.uiArray{ii} = WellSelector(this.IC.labelchoices{ii},this.IC.values{ii},...
%                         'parent',this);
                    
                    % put in a BoxPanel for clarity
                    tempbox = uix.BoxPanel('parent',this.MainVBox,'Title','Well Selection');
                    tempvb = uix.VBox('parent',tempbox);
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Newly inserted to use the new well browser
                    s = cell2mat(regexp(this.IC.labelchoices{ii},'(?<row>[A-Z])(?<col>\d{1,2})','names'));
                    r = double(upper([s.row]))'-64;
                    c = arrayfun(@(x)str2double(x.col),s);
%                     siz = [24,16];
                    this.PlateDimensions = plateSize; % siz should now be passed in the inputs
% % %                     present = amcSub2Ind(this.PlateDimensions,[c,r]);
                    present = amcSub2Ind(this.PlateDimensions([2,1]),[r,c]);
                    grouplist = ones(prod(this.PlateDimensions),1);
                    grouplist(present) = 2;
                    
                    current = present(this.IC.values{ii});
                    
% % %                     this.uiArray{ii} = ChoiceWellAxes(current,grouplist,this.PlateDimensions([2,1]),tempbox);
                    this.uiArray{ii} = ChoiceWellButtons(current,grouplist,this.PlateDimensions([2,1]),tempvb);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    
                    this.wellLstn = addlistener(this.uiArray{ii},'choiceUpdate',@this.wellcallback);
                    
                    this.panelWidth = 400;
                    this.hasWell = true;
                else


                    count = count + 1;
                    % put in a BoxPanel for clarity
                    tempbox = uix.BoxPanel('parent',this.hb,'Title',this.IC.longnames{ii});
                            
                    tempvb = uix.VBox('parent',tempbox);
                    % alternatively, make a boxpanel with the name of the
                    % option, instead of adding text
%                     uicontrol('Style','text','parent',tempvb,'String',this.IC.longnames{ii});

                    % check the label first, before falling back on the general
                    % options

                    switch this.IC.labels{ii}
                        case 'channel'
                            
                            this.uiArray{ii} = uicontrol('Style','listbox',...
                                'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                'parent',tempvb,'max',2,'min',0,...
                                'callback',{@this.clickcallback,ii,'list'});
                            
                            if any(strcmpi(this.LoadTriggers,'channel'))
                                allstr = 'Show All';
                            else
                                allstr = 'Select All';
                            end
                            
                            this.allToggleArray{ii} = uicontrol('Style','ToggleButton','Value',false,...
                              'parent',tempvb,'callback',{@this.clickcallback,ii,'button'},'String',allstr,...
                              'backgroundcolor',[0.93,0.93,0.93]);
                            count = count + 1;
                            this.chanidx = ii;
                            
                            set(tempvb,'heights',[-1,24])

                        case 'zslice'
                            this.uiArray{ii} = uicontrol('Style','listbox',...
                                'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                'parent',tempvb,'max',2,'min',0,...
                                'callback',{@this.clickcallback,ii,'list'});
                            
                            if any(strcmpi(this.LoadTriggers,'zslice'))
                                allstr = 'Show 3D';
                            else
                                allstr = 'Select 3D';
                            end
                            
                            this.allToggleArray{ii} = uicontrol('Style','ToggleButton','Value',false,...
                              'parent',tempvb,'callback',{@this.clickcallback,ii,'button'},'String',allstr,'backgroundcolor',[0.93,0.93,0.93]);
                            count = count + 1;
                            this.zidx = ii;
                            
                            set(tempvb,'heights',[-1,24])

                        case 'action'
                            this.uiArray{ii} = uicontrol('Style','listbox',...
                                'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                'parent',tempvb,'max',2,'min',0,...
                                'callback',{@this.clickcallback,ii,'list'});
                            
                            if any(strcmpi(this.LoadTriggers,'action'))
                                allstr = 'Show All';
                            else
                                allstr = 'Select All';
                            end
                            
                            this.allToggleArray{ii} = uicontrol('Style','ToggleButton','Value',false,...
                              'parent',tempvb,'callback',{@this.clickcallback,ii,'button'},'String',allstr,'backgroundcolor',[0.93,0.93,0.93]);
                            count = count + 1;
                            this.actidx = ii;
                            
                            set(tempvb,'heights',[-1,24])

                        case {'frame','timepoint','field','timeline'}
                            this.uiArray{ii} = uicontrol('Style','listbox',...
                                'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                'parent',tempvb,'max',2,'min',0,...
                                'callback',{@this.clickcallback,ii,'list'});

%                             this.allToggleArray{ii} = uix.Empty('parent',tempvb);
                            count = count + 1;
                            
                            set(tempvb,'heights',-1)


                        otherwise
                            switch this.IC.labeltype{ii}
                                case 'numeric'
                                    this.uiArray{ii} = uicontrol('Style','Slider',...
                                        'max',numel(this.IC.labelchoices{ii}),'min',1,...
                                        'parent',tempvb,'value',this.IC.values{ii},...
                                        'sliderstep',[1/(numel(this.IC.labelchoices{ii})-1),1],...
                                        'callback',{@this.clickcallback,ii,'list'});

                                case 'char'
                                    this.uiArray{ii} = uicontrol('Style','popupmenu',...
                                        'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                        'parent',temphb,...
                                        'callback',{@this.clickcallback,ii,'list'});


                                case 'logical'
                                    this.uiArray{ii} = uicontrol('Style','CheckBox',...
                                        'String','','parent',tempvb,'callback',{@this.logicalcallback,ii},...
                                        'Value',get(this.IC,ii));

                                case 'range'
                                    this.uiArray{ii} = uicontrol('Style','Slider',...
                                        'max',this.IC.labelchoices{ii}(2),'min',this.IC.labelchoices{ii}(1),...
                                        'parent',tempvb,'value',this.IC.values{ii},...
                                        'sliderstep',[1/(numel(this.IC.labelchoices{ii})-1),1],...
                                        'callback',{@this.callback,ii});


                                otherwise
                                    % edit box for a free range?
                                    error('Not implemented yet')

                            end
                            
                            set(tempvb,'heights',-1)
%                                     this.allToggleArray{ii} = uix.Empty('parent',tempvb);
                                    count = count + 1;

                    end
                    if any(strcmpi(this.IC.labels{ii},this.LoadTriggers))
                        set(tempbox,'TitleColor',[0.25,0.5,0.05])
                    end
                    
                    
                    
                end
                if ii==numel(this.IC.labels)
                    this.LoadButton = uicontrol('Style','PushButton',...
                          'parent',tempvb,'callback',@(src,evt)notify(this,'choiceUpdate'),...
                          'String','Load Image','backgroundcolor',[0.93,0.93,0.93]);
                      temphh = get(tempvb,'heights');
                      temphh(end) = 24;
                      set(tempvb,'heights',temphh)
                      
                      this.ButtonBox = tempvb;
                end
            end
            
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
            
            this.availChange();
            
            % at the end, setup the mode to be what we want
            if ~isempty(this.zidx) && numel(this.IC.labelchoices{this.zidx})>1
                this.clickcallback([],[],this.zidx,'all');
            end
            
            if ~isempty(this.actidx)
                this.clickcallback([],[],this.actidx,'all');
            else
                if ~isempty(this.chanidx)
                    this.clickcallback([],[],this.chanidx,'all');
                end
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
                
                    if labelidx==this.zidx
                        % subtract two from the mode if it's greater than 2
                        if this.blendMode==2 || this.blendMode==3
                            this.blendMode = this.blendMode - 2;
                        elseif this.blendMode==5
                            this.blendMode = 4;
                        end
                    elseif labelidx==this.chanidx
                        % subtract one from the mode
                        if this.blendMode==1 || this.blendMode==3
                            this.blendMode = this.blendMode - 1;
                        end
                    elseif labelidx==this.actidx
                        if this.blendMode==4
                            this.blendMode = 1;
                        elseif this.blendMode==5
                            this.blendMode = 3;
                        end
                        
                        % make sure that the channel box is clickable
                        set(this.uiArray{this.chanidx},'Enable','on')
                    end
                

                % get the value from the list box
                newval = round(get(this.uiArray{labelidx},'value'));
            else
                % clicked the 'all' button
                if isa(this.allToggleArray{labelidx},'matlab.ui.control.UIControl')
                    set(this.allToggleArray{labelidx},'Value',1,'backgroundcolor',[0.4,0.4,0.7])
                    
                    if labelidx==this.zidx
                        % add two to the mode
                        if this.blendMode==0 || this.blendMode==1
                            this.blendMode = this.blendMode + 2;
                        elseif this.blendMode==4
                            this.blendMode = 5;
                        end
                    elseif labelidx==this.chanidx
                        % add one to the mode
                        if this.blendMode==0 || this.blendMode==2
                        	this.blendMode = this.blendMode + 1;
                        end
                    elseif labelidx==this.actidx
                        if this.blendMode==0 || this.blendMode==1
                            this.blendMode = 4;
                        elseif this.blendMode==2 || this.blendMode==3
                            this.blendMode = 5;
                        end
                        
                        % also make sure that the channel button becomes
                        % selected, and can't be deselected until we pick a
                        % single action
                        set(this.allToggleArray{this.chanidx},'Value',1,'backgroundcolor',[0.4,0.4,0.7])
                        set(this.uiArray{this.chanidx},'Value',[])
                        set(this.uiArray{this.chanidx},'Enable','off')
                        
                        this.IC.directSet(this.chanidx,Inf);
                    end
                end
                
                set(this.uiArray{labelidx},'Value',[])

                newval = Inf;
            end
            
            this.IC.directSet(labelidx,newval);
            
            if any(strcmpi(this.IC.labels{labelidx},this.LoadTriggers))
                notify(this,'choiceUpdate')
            end
            
        end
        
        
        function wellcallback(this,src,evtd)
            % the well selector has been changed
            
            % the well string is contained in the eventdata
            wellstr = evtd.data;
            if isempty(wellstr)
                % need to change the well selection back to the current
                % choice
                setSelection(src,get(this.IC,'well')); % what is called here?
            else
%                 ind = find(cellfun(@(x)isa(x,'ChoiceWellAxes'),this.uiArray));
                ind = find(strcmpi('well',this.IC.labels)); % doesn't have to be a ChoiceWellAxes
                try
                this.IC.set(ind,wellstr)
                catch ME
                    rethrow(ME)
                end
                this.availChange();
                
                newidx = find(strcmpi(wellstr,this.IC.labelchoices{ind}));
                if ~isa(this.uiArray{ind},'ChoiceWellAxes') && ~isa(this.uiArray{ind},'ChoiceWellButtons')
                    set(this.uiArray{ind},'Value',newidx)
                end
                
                % don't necessarily want to trigger this here
                if any(strcmpi('well',this.LoadTriggers))
                    notify(this,'choiceUpdate')
                end
            end
            
        end
        
        function availChange(this,src,evt)
            % only do anything here if it's a hierarchical Index Choices
            
            % IMPORTANT!
            % There is an interface difference between HierImIndexChoices
            % and BlendHierImIC - the former uses a regular array rather
            % than a cell array to define aRelInd, and should be considered
            % as legacy code
            try
            if ~isa(this.IC,'BlendHierImIC')
                return
            end
            catch ME
                rethrow(ME)
            end
            
            [aChoices,aRelInd] = availChoices(this.IC);
            
            for ii = 1:numel(aChoices)
                % as the choices grow, would be better for each uiArray to
                % be its own class, which defines an updateChoices method
                
                % pick one, or ship the code to a method of the specific
                % well class
                if isa(this.uiArray{ii},'ChoiceWellButtons')
                    % need to reconstruct the grouplist here and send it
                    [r,c] = wellstr2rowcol(this.IC.labelchoices{ii}(aChoices{ii}));
                    
                    
% %                     s = cell2mat(regexp(this.IC.labelchoices{ii}(aChoices{ii}),'(?<row>[A-Z])(?<col>\d{1,2})','names'));
% %                     r = double(upper([s.row]))'-64;
% %                     c = arrayfun(@(x)str2double(x.col),s);
%                     siz = [24,16];
% % %                     present = amcSub2Ind(this.PlateDimensions,[c,r]);
                    present = amcSub2Ind(this.PlateDimensions([2,1]),[r,c]);
                    grouplist = ones(prod(this.PlateDimensions),1);
                    grouplist(present) = 2;
                    
                    current = present(aRelInd{ii});
                    
                    resetChoices(this.uiArray{ii},current,grouplist);
                    
% %                 elseif isa(this.uiArray{ii},'ChoiceWellAxes')
% %                     % need to reconstruct the grouplist here and send it
% %                     s = cell2mat(regexp(this.IC.labelchoices{ii}(aChoices{ii}),'(?<row>[A-Z])(?<col>\d{1,2})','names'));
% %                     r = double(upper([s.row]))'-64;
% %                     c = arrayfun(@(x)str2double(x.col),s);
% % %                     siz = [24,16];
% %                     present = amcSub2Ind(this.PlateDimensions,[c,r]);
% %                     grouplist = zeros(prod(this.PlateDimensions),1);
% %                     grouplist(present) = 2;
% %                     
% %                     current = present(aRelInd{ii});
% %                     
% %                     resetChoices(this.uiArray{ii},current,grouplist);
% %                     
% %                 elseif isa(this.uiArray{ii},'WellSelector')
% %                     resetChoices(this.uiArray{ii},this.IC.labelchoices{ii}(aChoices{ii}),aRelInd{ii});
                else
                    set(this.uiArray{ii},'String',this.IC.labelchoices{ii}(aChoices{ii}),'Value',aRelInd{ii});
                end
            end
            
        end
        
        function currVals = getCurrentValues(this)
            % return a cell array of the current choices, replacing any
            % 'all' options with the current range of values
            currVals = getCurrentValues(this.IC);
            
            % need to be careful in the case when all chan and all z are
            % selected, because different channels might have different
            % numbers of slices - for now this might need to be handled
            % outside in the ImageLoader, because it is problematic to have
            % different z options for different channels using a cell array
            % output like this, ie the interface would need changing!
            for ii = 1:numel(currVals)
                try
                if isinf(currVals{ii})
                    currVals{ii} = amcFlatten(availChoices(this.IC,ii));
                end
                catch ME
                    rethrow(ME)
                end
            end
            
        end
        
        function delete(this)
            % this should clean up the display
            delete(this.MainVBox)
            
%             disp('Hello, working')
        end
    end
end
