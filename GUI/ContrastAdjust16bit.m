classdef ContrastAdjust16bit < handle
    % attempt to bring together the curves adjustment and processing
    properties
        % start with the model properties
        procArray = {}
        lowval;
        hival;
        ix % reference points
        xx % cell array of interpolation points
        yy
        
        numCh % if this gets changed, update the curves to have the right number of channels
        chanIdx
        
        hgrams % this has been stored, but it would be good it we didn't need to..

        ylim = {}
        bh = {} % not sure these need storing, but do it anyway for now..

        % then the display properties, which cna be reused
        tabh
        vbArray
        axArray
        
        lowedit
        hiedit
        cutoffboxh
        autoh
        lowsl
        hisl
        % try storing the limits in the edit box directly (or in the value
        % of the slider) rather than having to have a separate property
        hfig % need the figure reference for window callbacks
        
        parenth
        
        ph = {}
        lh = {}
        
        ChannelLabels
        
        
        currind
        
        bcastfreq = 1
    end
    events
        settingsUpdate
        autoRequest
    end
    methods
        function obj = ContrastAdjust16bit(chanLabels,parent,initxx,inityy,chanidx)
            
            % separate the class initialization from the display, so that
            % the window can be opened and closed without losing the
            % settings
            
            
            if nargin>0 && ~isempty(chanLabels)
                if ~iscell(chanLabels) && isscalar(chanLabels)
                    numch = chanLabels;
                    chanLabels = arrayfun(@num2str,(1:numch)','uni',false);
                else
                    numch = numel(chanLabels);
                end
                
                obj.ChannelLabels = chanLabels;
                obj.numCh = numch;
                obj.xx = repmat({[0;1]},[obj.numCh,1]);
                obj.yy = repmat({[0;1]},[obj.numCh,1]);
                
                for ii = 1:obj.numCh
                    obj.procArray{ii} = CurvesLUT16bit(obj.xx{ii},obj.yy{ii});
                end
            else
                obj.numCh = 0;
            end
            obj.lowval = zeros(1,obj.numCh);
            obj.hival = 65535*ones(1,obj.numCh);
            
            if nargin>2 && ~isempty(initxx)
                obj.xx = initxx;
            end
            if nargin>3 && ~isempty(inityy)
                obj.yy = inityy;
            end
            for ii = 1:obj.numCh
                obj.ix{ii} = linspace(0,1,100);
            end
            
            if nargin<5 || isempty(chanidx)
                chanidx = 1:obj.numCh;
            end
            obj.chanIdx = chanidx;
            
            obj.ph = cell(obj.numCh,1);
            obj.lh = cell(obj.numCh,1);
            
            if nargin>1 && ~isempty(parent)
                obj.parenth = parent;
            end
            
        end
        
        function setNumCh(obj,newNumCh,newIdx)
            if newNumCh>obj.numCh
                obj.xx = [obj.xx;repmat({[0;1]},[newNumCh-obj.numCh,1])];
                obj.yy = [obj.yy;repmat({[0;1]},[newNumCh-obj.numCh,1])];
                
                for ii = (obj.numCh+1):newNumCh
                    obj.procArray{ii} = CurvesLUT16bit(obj.xx{ii},obj.yy{ii});
                end
                obj.numCh = newNumCh;
                if nargin<3 || isempty(newIdx)
                    newIdx = 1:obj.numCh;
                end
                obj.chanIdx = newIdx;
                
                % could also preinitialize the graphics handle arrays if we
                % wanted to
            else
                % remove the extra channels if there are any
                obj.xx = obj.xx(1:newNumCh);
                obj.yy = obj.yy(1:newNumCh);
                obj.procArray = obj.procArray(1:newNumCh);
                obj.numCh = newNumCh;
            end
            % at the end, check if anything was open, and if so close it
            % and reopen it
            if ~isempty(obj.autoh) && ishandle(obj.autoh(1))
                showGUI(obj);
            end
        end
        
        function showGUI(obj)
            % Add a couple of sliders to provide cutoffs for images which
            % have only used a tiny amount of the dynamic range, allowing
            % to prenormalise them first.
            
            % check to see if the figure is already displayed
            % just check one button, since they should never get separated
            if ~isempty(obj.autoh) && ishandle(obj.autoh(1))
                % instead of returning, a better option would be to close
                % everything and redraw them
                
                closeDisplay(obj);
            end
            
            if isempty(obj.parenth) || ~ishandle(obj.parenth)
                obj.parenth = gfigure(); % sort out the appearance later
                
                set(obj.parenth, 'units', 'normalized');
                height = min(0.7, 0.13 * obj.numCh);
                set(obj.parenth, 'position', [0.4 height*0.5 0.2 height]);
            end
            
%             obj.tabh = uix.TabPanel('parent',obj.parenth);
            obj.tabh = uix.VBox('parent',obj.parenth);

            obj.hfig = getFigParent(obj.tabh); % check the name of this function

            temptitles = cell(1,obj.numCh);
            
            for ii = 1:obj.numCh
                
                tempbox = uix.BoxPanel('parent',obj.tabh);
%                 obj.vbArray(ii) = uix.VBox('parent',obj.tabh);
                obj.vbArray(ii) = uix.VBox('parent',tempbox);
                
                obj.axArray(ii) = axes('units','normalized','position',[0.02,0.02,0.96,0.96],...
                  'xtick',[],'ytick',[],'parent',obj.vbArray(ii));

%                 obj.bh{ii} = bar(obj.axArray(ii),obj.ix{ii},obj.hgrams{ii}/max(obj.hgrams{ii}(:)),'hist');
%                 set(obj.bh{ii},'facecolor',[0.8,0.8,0.8])
                hold on

                obj.ylim{ii} = get(gca,'ylim');
                set(obj.axArray(ii),'xlim',[-0.02,1.02])

                % haven't checked what this does yet..
                obj.currind = [];

                % need an index for this now
                updateplot(obj,ii);
                
                try
% %                 set([obj.bh{ii},obj.axArray(ii)],'ButtonDownFcn',{@obj.bdownfun,ii})
                set(obj.axArray(ii),'ButtonDownFcn',{@obj.bdownfun,ii}) % bars not currently displayed, change back when they are
                catch ME
                    rethrow(ME)
                end
                
                % add another slider (or two) to adjust the range of the
                % image.  Additionally, a edit box showing the number and
                % an auto button might be useful
                
                obj.cutoffboxh(ii) = uix.HBox('parent',obj.vbArray(ii));
                
                % then add auto button, edit, two sliders in vbox, edit
                obj.autoh(ii) = uicontrol('Style','pushbutton','String','Auto',...
                    'parent',obj.cutoffboxh(ii),'callback',{@obj.autocallback,ii});
                obj.lowedit(ii) = uicontrol('Style','edit','parent',obj.cutoffboxh(ii));
                tempvb = uix.VBox('parent',obj.cutoffboxh(ii));
                
                obj.lowsl(ii) = uicontrol('Style','Slider','parent',tempvb);
                obj.hisl(ii) = uicontrol('Style','Slider','parent',tempvb);
                
                obj.hiedit(ii) = uicontrol('Style','edit','parent',obj.cutoffboxh(ii));
                
                set(obj.hisl(ii),'Max',65535,'Min',0,'Value',obj.hival(ii),'sliderstep',[1/256,1/16],...
                    'callback',{@obj.rangecallback,ii})
                set(obj.lowsl(ii),'Max',65535,'Min',0,'Value',obj.lowval(ii),'sliderstep',[1/256,1/16],...
                    'callback',{@obj.rangecallback,ii})
                set(obj.lowedit(ii),'String',num2str(get(obj.lowsl(ii),'Value')),...
                    'callback',{@obj.rangeeditcallback,ii})
                set(obj.hiedit(ii),'String',num2str(get(obj.hisl(ii),'Value')),...
                    'callback',{@obj.rangeeditcallback,ii})
                
                set(obj.cutoffboxh(ii),'widths',[-1,-1,-4,-1])
                set(obj.vbArray(ii),'heights',[-5,-1])
                
                temptitles{ii} = sprintf('Channel %s',obj.ChannelLabels{obj.chanIdx(ii)});
                set(tempbox,'Title',temptitles{ii});
            end
%             set(obj.tabh,'TabTitles',temptitles)
        end
        
        function closeDisplay(obj)
            % remove the graphical components, but keep the persistent info
            % for when it needs to come back again
            error('Not finished yet')
        end
        
        function rangecallback(obj,src,evt,ii)
            % slider adjusted, change the edit boxes to match
            % speed shouldn't be an issue, so update both (even though only
            % one has changed)
            
            obj.lowval(ii) = get(obj.lowsl(ii),'value');
            obj.hival(ii) = get(obj.hisl(ii),'Value');
            
            set(obj.lowedit(ii),'String',num2str(obj.lowval(ii)))
            set(obj.hiedit(ii),'String',num2str(obj.hival(ii)))
            
            
            updateProcArray(obj)
            notify(obj,'settingsUpdate')
        end
        
        function rangeeditcallback(obj,src,evt,ii)
            % check that the values entered into the edit box are genuine
            % numbers, and if so, update the sliders accordingly
            
            templow = str2double(get(obj.lowedit(ii),'String'));
            temphigh = str2double(get(obj.hiedit(ii),'String'));
            
            if isnan(templow)
                % set back to the value of the slider
                set(obj.lowedit(ii),'String',get(obj.lowsl(ii),'Value'))
            else
                % update the value of the slide
                % check for the range first
                if templow<get(obj.lowsl(ii),'Min')
                    set(obj.lowsl(ii),'min',templow,'value',templow)
                elseif templow>get(obj.lowsl(ii),'Max')
                    set(obj.lowsl(ii),'max',templow,'value',templow)
                else
                    set(obj.lowsl(ii),'value',templow);
                end
                obj.lowval(ii) = templow;
            end
            if isnan(temphigh)
                % set back to the value of the slider
                set(obj.hiedit(ii),'String',get(obj.hisl(ii),'Value'))
            else
                % update the value of the slide
                % check for the range first
            
                if temphigh<get(obj.hisl(ii),'Min')
                    set(obj.hisl(ii),'min',temphigh,'value',temphigh)
                elseif temphigh>get(obj.hisl(ii),'Max')
                    set(obj.hisl(ii),'max',temphigh,'value',temphigh)
                else
                    set(obj.hisl(ii),'value',temphigh);
                end
                obj.hival(ii) = temphigh;
            end
            updateProcArray(obj)
            notify(obj,'settingsUpdate')
        end
        
        function autocallback(obj,src,evt,ii)
            % set the values based on the currently displayed image
            % this needs to be obtained from the ImgExplorer, which will be
            % listening out for the request, and in response will call the
            % infoupdate method below.
            evtdata = GenEvtData(obj.chanIdx(ii));
            notify(obj,'autoRequest',evtdata);
        end
        
        function infoupdate(obj,imlimits,idx)
            % now we've got the image information
            templow = double(imlimits(1));
            temphigh = double(imlimits(2));
            
            ii = find(obj.chanIdx==idx);
            if numel(ii)~=1
                error('Unknown channel')
            end
            
            if templow<get(obj.lowsl(ii),'Min')
                set(obj.lowsl(ii),'min',templow,'value',templow)
            elseif templow>get(obj.lowsl(ii),'Max')
                set(obj.lowsl(ii),'max',templow,'value',templow)
            else
                set(obj.lowsl(ii),'value',templow);
            end
            
            if temphigh<get(obj.hisl(ii),'Min')
                set(obj.hisl(ii),'min',temphigh,'value',temphigh)
            elseif temphigh>get(obj.hisl(ii),'Max')
                set(obj.hisl(ii),'max',temphigh,'value',temphigh)
            else
                set(obj.hisl(ii),'value',temphigh);
            end
            
            set(obj.lowedit(ii),'String',num2str(templow))
            set(obj.hiedit(ii),'String',num2str(temphigh))
            
            obj.hival(ii) = temphigh;
            obj.lowval(ii) = templow;
            
            notify(obj,'settingsUpdate')
            
        end
        
        function bdownfun(obj,src,evt,ind)

            set(obj.hfig,'WindowButtonUpFcn',{@obj.bupfun,ind})
            set(obj.hfig,'WindowButtonMotionFcn',{@obj.Move,ind})

            % also check for the location of the click, and if sufficiently far
            % from an existing point, create a new one
            % should be able to check the source for this..

            pos = get(obj.axArray(ind),'CurrentPoint');
            if src~=obj.ph{ind}
                % create new point

                [obj.xx{ind},ord] = sort([obj.xx{ind};pos(1,1)]);
                obj.yy{ind} = arrayReference([obj.yy{ind};pos(1,2)],ord);

                obj.currind = find(ord==numel(obj.xx{ind}));

                updateplot(obj,ind);
            else
                % find the current point
                xdist = abs(obj.xx{ind}-pos(1,1));
                obj.currind = find(xdist==min(xdist),1,'first');
            end
        end

        function bupfun(obj,src,evt,ind)
            set(obj.hfig,'WindowButtonMotionFcn','')
            set(obj.hfig,'WindowButtonMotionFcn','')
            % attempt to broadcast an event to anyone listening for a change
            obj.currind = [];

            if obj.bcastfreq>0
                updateProcArray(obj)
                notify(obj,'settingsUpdate')
            end
        end

        function Move(obj,src,evt,ind)
            % might not be worth updating the interpolation for this

            pos = get(obj.axArray(ind),'CurrentPoint');

            if obj.currind~=1 && obj.currind~=numel(obj.xx{ind})
                % only allow x to change if it's not one of the ends
                newx = pos(1,1);

                % if it's gone past either of the adjacent points, merge them
                if newx<=obj.xx{ind}(obj.currind-1)
                    obj.xx{ind}(obj.currind-1) = [];
                    obj.yy{ind}(obj.currind-1) = [];
                    obj.currind = obj.currind - 1;
                elseif newx>=obj.xx{ind}(obj.currind+1)
                    obj.xx{ind}(obj.currind+1) = [];
                    obj.yy{ind}(obj.currind+1) = [];
                end

                obj.xx{ind}(obj.currind) = newx;
            end

            obj.yy{ind}(obj.currind) = max(obj.ylim{ind}(1),min(obj.ylim{ind}(2),pos(1,2)));

            % try updating the interpolation within the plot

            updateplot(obj,ind);

            if obj.bcastfreq==2
                % broadcast the change here.
                updateProcArray(obj)
                notify(obj,'settingsUpdate')
            end
        end

        function updateplot(obj,ind)
            if isa(obj.ph{ind},'matlab.graphics.Graphics')
                delete(obj.ph{ind})
            end
            if isa(obj.lh{ind},'matlab.graphics.Graphics')
                delete(obj.lh{ind})
            end
            
            smy = interp1(obj.xx{ind},obj.yy{ind},obj.ix{ind},'pchip');
            obj.lh{ind} = plot(obj.ix{ind},smy,'-b');
            obj.ph{ind} = plot(obj.xx{ind},obj.yy{ind},'ob','markerfacecolor',[0.3,0.3,1]);
            set([obj.ph{ind},obj.lh{ind}],'ButtonDownFcn',{@obj.bdownfun,ind})
        end

        function updateProcArray(obj)
            % this part taken from curvesproc.updateSettings and moved here
            % if too slow, might be able to specify which channel has been
            % updated.
            
            try
            for ii = 1:numel(obj.xx)
                obj.procArray{ii}.xx = obj.xx{ii};
                obj.procArray{ii}.yy = obj.yy{ii};
                obj.procArray{ii}.xrange = [obj.lowval(ii), obj.hival(ii)];
                obj.procArray{ii}.generateLUT();
            end
            catch ME
                rethrow(ME)
            end
        end
        
        function fim = process(obj,imData)
            % the processing can be shipped to here, making it more modular
            % than having the explorer having to know about the processing
            fim = cell(size(imData));
            for ii = 1:numel(imData)
                % in the current version imData needs to be scaled between
                % zero and 1 before sending to the LUT
                
                imlim = [obj.lowval(ii),obj.hival(ii)];
                
                nim = max(0,min(1,(double(imData{ii})-imlim(1))/(imlim(2)-imlim(1))));
                
                fim(ii) = process(obj.procArray{ii},{nim});
            end
        end
        
        function fim = chanProcess(obj,im,idx)
            % only process a single channel if we need to
            % in this case, im should be just a regular array, not a cell
            % of channels
            
            chan = find(obj.chanIdx==idx);
            if numel(chan)~=1
                error('Unknown channel')
            end
            
            if ~iscell(im)
                imlim = [obj.lowval(chan),obj.hival(chan)];
                
                nim = max(0,min(1,(double(im)-imlim(1))/(imlim(2)-imlim(1))));
                fim = process(obj.procArray{chan},nim);
            else
                imlim = [obj.lowval(chan),obj.hival(chan)];
                
                nim = max(0,min(1,(double(im{chan})-imlim(1))/(imlim(2)-imlim(1))));
                fim = process(obj.procArray{chan},nim);
            end
        end

        function refreshHistograms(obj,hgrams)
            % might be worth updating these at some point
            error('Not implemented yet')
        end

        function reset(obj,ind)
            if nargin<2 || isempty(ind)
                ind = 1:numel(obj.xx);
            end
            for ii = 1:numel(ind)
                obj.xx{ind(ii)} = [0;1];
                obj.yy{ind(ii)} = [0;1];
                
                if ~isempty(obj.autoh) && ishandle(obj.autoh(1))
                    updateplot(obj,ind(ii));
                end
                
            end
            
            updateProcArray(obj)
            notify(obj,'settingsUpdate')
        end
        
        function lut = getLUT(obj,idx)
            chan = find(obj.chanIdx==idx);
            if numel(chan)~=1
                warning('Unknown channel')
                lut = linspace(0,1,65536);
            else

                % might want to updateProcArray first, if it's not too slow?

                lut = obj.procArray{chan}.ylut;
            end
        end
    end
end
