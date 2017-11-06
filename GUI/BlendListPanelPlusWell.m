classdef BlendListPanelPlusWell < uix.VBox
    properties
        IC
        
        hb
        uiArray
        valhArray
        showUnique = true;
        
        panelWidth
        hasWell = false;
        
        hierLstn % listener for the choices being updated by a hierarchical choices object
        % should this be a separate sub-class?
        wellLstn % listener for the well choice being changed
        
        panelHeight = 300;

        % additional properties required
        blh % handle to blend BoxPanel
        tickArray % handles to the tickboxes

        blendMode = 0;

        chanh
        zh % shortcuts to the appropriate sliders
        
        % LoadTriggers can potentially be changed by the user depending on
        % preference
        LoadTriggers = {'channel','zslice'};
    end
    events
      choiceUpdate
    end
    methods
        function this = BlendListPanelPlusWell(IC,varargin)
      
            this = this@uix.VBox(varargin{:});
            
            this.IC = IC;
            
            % the choices should already be set to something possible
            this.hierLstn = addlistener(this.IC,'availUpdate',@this.availChange);
            
            this.hb = uix.HBox('parent',this);
            
            count = 0;
            this.panelWidth = [];
            
            % find out which is the last label?
            
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
                    tempbox = uix.BoxPanel('parent',this,'Title','Well Selection');
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Newly inserted to use the new well browser
                    s = cell2mat(regexp(this.IC.labelchoices{ii},'(?<row>[A-Z])(?<col>\d{1,2})','names'));
                    r = double(upper([s.row]))'-64;
                    c = arrayfun(@(x)str2double(x.col),s);
                    siz = [24,16];
                    present = amcSub2Ind(siz,[c,r]);
                    grouplist = zeros(prod(siz),1);
                    grouplist(present) = 2;
                    
                    current = present(this.IC.values{ii});
                    
                    this.uiArray{ii} = ChoiceWellAxes(current,grouplist,siz([2,1]),tempbox);
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
                                'parent',tempvb,...
                                'callback',{@this.indexcallback,ii});

                            this.valhArray(ii) = uicontrol('Style','text',...
                                'String',sprintf('%d / %d',...
                                this.IC.labelchoices{ii}(this.IC.values{ii}),...
                                numel(this.IC.labelchoices{ii})),...
                                'Parent',tempvb);
                            
                            this.tickArray{ii} = uicontrol('Style','ToggleButton','Value',false,...
                              'parent',tempvb,'callback',{@this.toggleBlend,ii,1},'String','Show all');
                            count = count + 1;
                            this.chanh = this.uiArray{ii};

                        case 'zslice'
                            this.uiArray{ii} = uicontrol('Style','listbox',...
                                'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                'parent',tempvb,...
                                'callback',{@this.indexcallback,ii});

                            this.valhArray(ii) = uicontrol('Style','text',...
                                'String',sprintf('%d / %d',...
                                this.IC.labelchoices{ii}(this.IC.values{ii}),...
                                numel(this.IC.labelchoices{ii})),...
                                'Parent',tempvb);
                            
                            this.tickArray{ii} = uicontrol('Style','ToggleButton','Value',false,...
                              'parent',tempvb,'callback',{@this.toggleBlend,ii,2},'String','Show all');
                            count = count + 1;
                            this.zh = this.uiArray{ii};

                        case {'frame','timepoint','field','timeline','action'}
                            this.uiArray{ii} = uicontrol('Style','listbox',...
                                'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                'parent',tempvb,...
                                'callback',{@this.indexcallback,ii});

                            this.valhArray(ii) = uicontrol('Style','text',...
                                'String',sprintf('%d / %d',...
                                this.IC.labelchoices{ii}(this.IC.values{ii}),...
                                numel(this.IC.labelchoices{ii})),...
                                'Parent',tempvb);
                            
                            this.tickArray{ii} = uix.Empty('parent',tempvb);
                            count = count + 1;


                        otherwise
                            switch this.IC.labeltype{ii}
                                case 'numeric'
                                    this.uiArray{ii} = uicontrol('Style','Slider',...
                                        'max',numel(this.IC.labelchoices{ii}),'min',1,...
                                        'parent',tempvb,'value',this.IC.values{ii},...
                                        'sliderstep',[1/(numel(this.IC.labelchoices{ii})-1),1],...
                                        'callback',{@this.indexcallback,ii});

                                    this.valhArray(ii) = uicontrol('Style','text',...
                                        'String',num2str(this.IC.labelchoices{ii}(this.IC.values{ii})),...
                                        'Parent',tempvb);
                                    

                                case 'char'
                                    this.uiArray{ii} = uicontrol('Style','popupmenu',...
                                        'String',this.IC.labelchoices{ii},'value',this.IC.values{ii},...
                                        'parent',temphb,...
                                        'callback',{@this.indexcallback,ii});

                                    this.valhArray(ii) = uix.Empty('parent',tempvb);


                                case 'logical'
                                    this.uiArray{ii} = uicontrol('Style','CheckBox',...
                                        'String','','parent',tempvb,'callback',{@this.logicalcallback,ii},...
                                        'Value',get(this.IC,ii));

                                    this.valhArray(ii) = uix.Empty('parent',tempvb);

                                case 'range'
                                    this.uiArray{ii} = uicontrol('Style','Slider',...
                                        'max',this.IC.labelchoices{ii}(2),'min',this.IC.labelchoices{ii}(1),...
                                        'parent',tempvb,'value',this.IC.values{ii},...
                                        'sliderstep',[1/(numel(this.IC.labelchoices{ii})-1),1],...
                                        'callback',{@this.callback,ii});


                                    this.valhArray(ii) = uicontrol('Style','text',...
                                        'String',num2str(this.IC.labelchoices{ii}(this.IC.values{ii})),...
                                        'Parent',tempvb);

                                otherwise
                                    % edit box for a free range?
                                    error('Not implemented yet')

                            end
                            
                                    this.tickArray{ii} = uix.Empty('parent',tempvb);
                                    count = count + 1;

                    end
                    if any(strcmpi(this.IC.labels{ii},this.LoadTriggers))
                        set(tempbox,'TitleColor',[0.25,0.5,0.05])
                    end
                    try
                    set(tempvb,'heights',[-1,40,40])
                    catch ME
                        rethrow(ME)
                    end
                end
            end
            
            if isempty(this.panelWidth)
                this.panelWidth = max(200,50*count);
            end
            
            % rearrange the order here so that the well appears at the top
            if this.hasWell
                set(this.hb,'parent',[])
                set(this.hb,'parent',this)
%                 set(this,'Children',flipud(get(this,'Children')))
                set(this,'Heights',[-1.6,-1]);
            end
            
            this.availChange();
            
        end
        function toggleBlend(this,src,evt,boxidx,czind)
            % get the updated mode, enable or disable the sliders accordingly and then
            % trigger an event
            newval = get(this.tickArray{boxidx},'Value');

            % get the previous modes
            currcz = [this.blendMode - 2*floor(this.blendMode/2),floor(this.blendMode/2)];
            currcz(czind) = newval;
            % check the maths here!
            this.blendMode = sum([1,2].*currcz);

            switch czind
              case 1
                  if newval
                      set(this.chanh,'enable','off')
                  else
                      set(this.chanh,'enable','on')
                  end
              case 2
                  if newval
                      set(this.zh,'enable','off')
                  else
                      set(this.zh,'enable','on')
                  end
              otherwise
                  error('Shouldn''t get here')
            end
            
            notify(this,'choiceUpdate')
            
        end
    
        function indexcallback(this,src,evt,ind)
            % a stored-by-index value has been changed
            % make sure that the index is a whole number and update the
            % IndexChoices object and the GUI
            
            newval = round(get(this.uiArray{ind},'value'));
            
            % before setting, find out what the previous value was, and
            % then only load the image if it's the same?
            this.IC.directSet(ind,newval);
            
%             this.availChange();
            
            % check the rounding for the GUI
            set(this.uiArray{ind},'value',newval);
            
            if ~strcmpi(this.IC.labeltype{ind},'char')
                % update the text display
                set(this.valhArray(ind),'String',num2str(get(this.IC,ind)))
            end
            
            % trigger an event for anything listening for changes
            % TODO
            % Change this part so that the event is only triggered if the
            % last non-unique and non-blended option is clicked
            if any(strcmpi(this.IC.labels{ind},this.LoadTriggers))
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
                setSelection(src,get(this.IC,'well'));
            else
                ind = find(cellfun(@(x)isa(x,'ChoiceWellAxes'),this.uiArray));
                this.IC.set(ind,wellstr)
                
                this.availChange();
                
                newidx = find(strcmpi(wellstr,this.IC.labelchoices{ind}));
                if ~isa(this.uiArray{ind},'ChoiceWellAxes')
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
            
            try
            if ~isa(this.IC,'HierImIndexChoices')
                return
            end
            catch ME
                rethrow(ME)
            end
%             if nargin>1
%                 % we might have to change some behaviour depending on
%                 % whether this method has been triggered or called directly
%             end
            % at the moment I think this may get called twice, once by the
            % GUI and once by the listener - look into this
            
            [aChoices,aRelInd] = availChoices(this.IC);
            
            for ii = 1:numel(aChoices)
                % as the choices grow, would be better for each uiArray to
                % be its own class, which defines an updateChoices method
                
                % pick one, or ship the code to a method of the specific
                % well class
                if isa(this.uiArray{ii},'WellSelector')
                    resetChoices(this.uiArray{ii},this.IC.labelchoices{ii}(aChoices{ii}),aRelInd(ii));
                elseif isa(this.uiArray{ii},'ChoiceWellAxes')
                    % need to reconstruct the grouplist here and send it
                    s = cell2mat(regexp(this.IC.labelchoices{ii}(aChoices{ii}),'(?<row>[A-Z])(?<col>\d{1,2})','names'));
                    r = double(upper([s.row]))'-64;
                    c = arrayfun(@(x)str2double(x.col),s);
                    siz = [24,16];
                    present = amcSub2Ind(siz,[c,r]);
                    grouplist = zeros(prod(siz),1);
                    grouplist(present) = 2;
                    
                    current = present(aRelInd(ii));
                    
                    resetChoices(this.uiArray{ii},current,grouplist);
                    
                else
                    set(this.uiArray{ii},'String',this.IC.labelchoices{ii}(aChoices{ii}),'Value',aRelInd(ii));
                end
            end
            
        end
    end
end
