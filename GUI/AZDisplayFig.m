classdef AZDisplayFig < handle
    % manager for the display objects when used outside YE
    properties
        Fig
        DispObj
        ContrastObj; % object responsible for contrast adjustment
        ContrastLstnr; % listener for changes in contrast
        AutoContrastLstnr % listener for clicking the autocontrast button
        NewImageLstnr % listener for a new image being generated and needing displaying
    end
    methods
        function this = AZDisplayFig(fig,dispObj,conObj)
            % single display figure takes a pre-existing display object in the constructor, so we can
            % get the scroll function from that and set it here

            this.Fig = fig;
            this.ContrastObj = conObj;
            this.DispObj = dispObj;

            fighandle = getFigParent(this.Fig);
            temp = uimenu(fighandle,'Label','View');

            % also want options for zooming and panning
            % put these in the menu as well, since there's already one
            % there..
            uimenu(temp,'Label','Zoom','callback',@(src,evt)zoom(fighandle))
            uimenu(temp,'Label','Pan','callback',@(src,evt)pan(fighandle))

            if ~(isnumeric(this.ContrastObj) && isnan(this.ContrastObj))
                this.ContrastLstnr = addlistener(this.ContrastObj,'settingsUpdate',@this.refreshPanels);
                this.AutoContrastLstnr = addlistener(this.ContrastObj,'autoRequest',@this.autoContrast);

                % add a menu to the figure to allow the contrast adjustment to
                % be brought up


                uimenu(temp,'Label','Contrast Adjustment','callback',...
                    @this.contrastcallback);
                uimenu(temp,'Label','Auto Contrast','callback',...
                    @this.autocontrastcallback);
            end
            
            this.NewImageLstnr = addlistener(this.DispObj,'imageEvent',@this.imageEventCallback);

            % also add a menu entry to save a snapshot of the current
            % figure
            temp = uimenu(fighandle,'Label','Snapshot');
            uimenu(temp,'Label','Save to file...','callback',{@this.savesnapshot,'-r100'})
            uimenu(temp,'Label','Copy to clipboard','callback',@(src,evt)IAHelp())

            % for a single figure, can set the WindowScrollWheelFcn directly
            set(fighandle, 'WindowScrollWheelFcn', this.DispObj.getScrollFun)
        end

% %         function savesnapshot(this,src,evt)
% %             IAHelp()
% %             return
% % 
% % 
% %             fig = figure;
% %             ax = copyobj(oldax,fig);
% %             set(ax,'activepositionproperty','outerposition','position',[0,0,1,1]);
% %             set(ax,'units','normalized','position',[0,0,1,1]);
% %         end

        
        function savesnapshot(this,src,evt,res)
            % first need to identify the current axes and copy them to an
            % invisible figure

            
            if nargin<4 || isempty(res)
                res = '-r100';
            end
            
% %             wb = SpinWheel('Saving Snapshot');
            progressBarAPI('init','Saving Snapshot');
            
            fig = gfigure('visible','off');

            % a better approach would be to let the DisplayObject determine
            % what is copied across - basically provide a graphics handle
            % containing the important parts
            this.DispObj.snapshotCopy(fig);
            
            savename = sprintf('Snapshot%s',datestr(now,'dd-mm-yy_HHMM-SS'));
            
            set(fig,'inverthardcopy','off')
            print(fig,'-dtiff',res,savename)

            close(fig)
% %             delete(wb)
            progressBarAPI('finish');
        end

        
        function refreshPanels(this,src,evt)
            % refresh the image

            % flag the colourmaps to be recalculated
            % at the moment, all the colourmaps are being flagged, but in theory
            % some time could be saved by being able to specify which ones are necessary
            tempImObj = getImObj(this.DispObj);

            for ii = 1:numel(tempImObj.Channel)
                this.DispObj.colourCallback([],[],ii,[])
            end

            this.DispObj.showImage();

        end

        function autoContrast(this,src,evt)


            % this requires some more work to figure out which channel
            % belongs to which figure


            % this line needed changing because the annotated image no
            % longer has a Channel property, but the ImObj contained within
            % it does.

%             tempImObj = this.DispObj.ImObj;
            tempImObj = getImObj(this.DispObj);

            chanind = evt.data==tempImObj.Channel;
            if nnz(chanind)==1
                % see if we can get the limits from the image data
                rawdata = tempImObj.rawdata();
                if iscell(rawdata)
                    rawdata = rawdata{chanind};
                end

                imlimits = [min(rawdata(:)),max(rawdata(:))];

                infoupdate(this.ContrastObj,imlimits,evt.data)
            end

            % need to check here whether to flag the channel for cmap recalculations

        end

        function autocontrastcallback(this,src,evt)
            % want to automatically set the contrast based on the
            % histograms of the current image, if possible
            
% %             wb = SpinWheel('Calculating auto contrast');
            progressBarAPI('init','Calculating auto contrast');

            tempImObj = this.DispObj.ImObj;

            % see if we can get the limits from the image data
            rawdata = tempImObj.rawdata();
            if ~iscell(rawdata)
                rawdata = {rawdata};
            end

            % try some basic equalization
            % if we want the image to be approximately exponentially
            % distributed, then?
            for ii = 1:numel(rawdata)
                % need to know what channel this corresponds to
                ch = tempImObj.Channel(ii);

%                 tempyy = (0:0.2:1)';
                tempyy = [0;0.7;1];
                hval = max(rawdata{ii}(:));
                lval = min(rawdata{ii}(:));

                nn = cumsum(imhist(rawdata{ii}(:),65536));
                nn = nn/nn(end);
                tempidx = find(nn<0.7,1,'last');
                if isempty(tempidx)
                    tempidx = 65536;
                end
                tempxx = [0;tempidx/65536;1];

                tempxx = 0.5*tempyy + 0.5*tempxx;

                this.ContrastObj.lowval(ch) = lval;
                this.ContrastObj.hival(ch) = hval;

                this.ContrastObj.xx{ch} = tempxx;
                this.ContrastObj.yy{ch} = tempyy;

            end
%             notify(this.ContrastObj,'settingsUpdate')
            % just call the method directly
            updateProcArray(this.ContrastObj)
            refreshPanels(this);

% %             delete(wb);
            progressBarAPI('finish');
        end

        function contrastcallback(this,src,evt)
            this.ContrastObj.showGUI;
        end
        
        function imageEventCallback(this,src,evt)
            % show the image in a new window, but using the same contrast
            % adjustment object
            evt.data.showImage(this.ContrastObj);
        end

    end
end
