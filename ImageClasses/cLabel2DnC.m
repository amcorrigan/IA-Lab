classdef cLabel2DnC < cLabelInterface
    % Label matrix class for storing the result of segmentations
    % see RegionLabels for the previous attempt at this, which stored the
    % pixel lists rather than the label array itself
    
    % The next question is what should be stored with the labels, centroid?
    % regionprops outputs? Centroid might be useful for overloading plot
    % calls for example?
    
    properties (Dependent)
        SizeX
        SizeY
        
    end
    properties
        ImSize
        Name
        LData % basic label array
        NumLabels = 0;
        
        NativeMap% default colour map when none is specified, like NativeColour for images
%         CMap_  % private cmap to stop MATLAB complaining about using other properties in the setting..
        NumChannel = 1;
        RPerm
        BorderXY = [];
    end
    
    methods
        % to begin with, just a wrapper for a label array, but down the
        % line there will be different variants - eg multi-'channel' would
        % be cells, nuclei, punctae, eg.
        function this = cLabel2DnC(L,cmap)
            % currently no check making sure it's only a 2D array that is
            % passed.
            if nargin>0 && ~isempty(L)
                if ~iscell(L)
                    L = {L};
                end
                
                % check for any labels which are logical and remove them
                % while it would be better for memory to keep them, it
                % messes up some of the indexing operations used when
                % calculating colours
                for ii = 1:numel(L)
                    if islogical(L{ii})
                        L{ii} = uint8(L{ii});
                    end
                end
                
                this.LData = L;
                this.NumLabels = cellfun(@(x)max(double(x(:))),this.LData);
                this.generateRPerm();
                
                this.NumChannel = numel(this.LData);
            end
            
            if nargin<2 || isempty(cmap)
                cmap = cell(this.NumChannel,1);
                
                for ii = 1:numel(cmap)
                    switch mod(ii,3)
                        case 0
                            cmap{ii} = jet(256);
                        case 1
                            cmap{ii} = summer(256);
                        otherwise
                            cmap{ii} = autumn(256);
                    end
                end
            end
            
            if ~iscell(cmap)
                cmap = {cmap};
            end
            
            this.NativeMap = cmap;
            % set the label sizes automatically at the start
            this.setLabelSize();
        end
        
        function generateRPerm(this)
            this.RPerm = arrayfun(@(x)randperm(x)',this.NumLabels,'uniformoutput',false);
        end
        
        function setLabelSize(this,lSize)
            if nargin<2 || isempty(lSize)
                lSize = size(this.LData{1});
            end
            
            this.ImSize = lSize;
        end
        
        function flipData(this)
            for i = 1:this.NumChannel
                this.LData{i} = flipud(this.LData{i});
            end;
        end        
% %         function set.CMap(this,cmap)
% %             % check that this gets called from the constructor
% % %             n = this.NumLabels;
% % %             if n==0
% %                 n = 255;
% % %             end
% %             if ischar(cmap)
% %                 % not sure if feval can be compiled?
% %                 this.CMap_ = feval(cmap,n);
% %             end
% %             
% %         end
        
% %         function cmap = get.CMap(this)
% %             cmap = this.CMap_;
% %         end
        
        function val = get.SizeX(this)
            val = this.ImSize(1);
        end
        function val = get.SizeY(this)
            val = this.ImSize(2);
        end
        
        % then also need some show methods
        % Like for the image class, rather than impose the display here,
        % instead provide the output in the appropriate format
        function L = rawdata(this)
            L = this.LData;
        end
        
        function im = getData2D(this)
            im = getLabel2D(this);
        end
        
        function im = getData3D(this)
            im = getLabel2D(this);
        end
        
        function L = getLabel2D(this)
            % return the label matrix but shuffled.  How can we sort out
            % the background colour?
            
            L = cell(this.NumChannel,1);
            for ii = 1:this.NumChannel
%                 vals = [0;this.RPerm{ii}]/this.NumLabels(ii); % needs to go from 0 to 1
                vals = [0;this.RPerm{ii}];
                L{ii} = vals(this.LData{ii} + 1);
            end
        end
        
        function L = getLabel3D(this)
            L = getLabel2D(this);
        end
        
        function varargout = getOutline2D(this)
            
            if isempty(this.BorderXY)
    %             if nargin<2 || isempty(skip)
                    skip = 8;
    %             end
    %             if nargin<3 || isempty(interpfact)
                    interpfact = 4;
    %             end

                L = getLabel2D(this);
                this.BorderXY = cell(numel(L),1);
                for ii = 1:numel(this.BorderXY)
                    try
                    this.BorderXY{ii} = label2outline(L{ii},skip,interpfact);
                    catch ME
                        rethrow(ME)
                    end
                end
            end
            
            % this process can be very slow, so we store the output so that
            % it only gets calculated once.
            if nargout>0
                varargout{1} = this.BorderXY;
            end
            
        end
        
        function pHandles = showAnnotation(this,cmaps,parenth)
            
            borderXY = this.getOutline2D();
            
            if ~iscell(cmaps)
                cmaps = {cmaps};
            end
            
            pHandles = cell(numel(borderXY),1);
            
            for ii = numel(borderXY):-1:1
                if numel(borderXY{ii})>0
% %                     if get(this.LabelShowCheckBoxes(ii),'value')
                    if ~(isscalar(cmaps{ii}) && isnan(cmaps{ii}))
                        

                        if size(cmaps{ii},1)==1
                            % single colour
                            try
                            usemap = linspace(0.25,1,255)' * cmaps{ii};
                            catch ME
                                rethrow(ME)
                            end
                        else
                            usemap = cmaps{ii};
                        end

                        for jj = 1:numel(borderXY{ii})
                            % take the nearest colour
                            colidx = 1 + ceil((size(usemap,1)-1)*(jj-1)/(max(numel(borderXY{ii}),2)-1));
                            col = usemap(colidx,:);
                            pHandles{ii}(jj) = patch('xdata',borderXY{ii}{jj}(:,2),'ydata',borderXY{ii}{jj}(:,1),...
                                'edgecolor',col,'facecolor',col,'parent',parenth,...
                                'linewidth',1.5,'facealpha',0.1);
                        end

                    end
                end
            end
            
        end
        
    end
    
    
    
    methods % cPixelDataInterface implementation
        function dispObj = defaultDisplayObject(~,panelh,~,dispInfo)
            % third input missing because contrast information isn't really
            % relevant for pure label matrix
            newFig = false;
            if nargin<2 || isempty(panelh)
                newFig = true;
                panelh = gfigure('Name','LabelView'); % not always going to be used in the explorer
            end
            
            if nargin<4
                info = [];
            end
            
            dispObj = cBasicMultiLabelDisplay2D(panelh,NaN,info); % doesn't exist yet
            
            if newFig
                azfig = AZDisplayFig(panelh,dispObj,NaN);
            end
            
        end
        
        function varargout = showImage(this)
            % this is exactly the same as cImage2D, but I don't know how
            % easily the code for the two can be put in a single place
            % A Pixel2D class perhaps? Depends on if there are enough
            % common functions
            
            dispObj = defaultDisplayObject(this);
            outputh = showImage(dispObj,this);
            if nargout>0
                varargout{1} = dispObj;
                if nargout>1
                    varargout{2} = outputh;
                end
            end
        end
        
        function cval = getNativeColour(this,ind)
            cval = this.NativeMap{ind};
        end
        
        function sliceL = getSlice(this,sliceaxis,planeIdx,labelidx)
            if nargin<4 || isempty(labelidx)
                labelidx = 1;
            end
            
            switch lower(sliceaxis)
                case 'x'
                    sliceL = this.LData{labelidx}(planeIdx,:,:);
                    sliceL = permute(sliceL,[3,2,1]);
                case 'y'
                    sliceL = this.LData{labelidx}(:,planeIdx,:);
                    sliceL = permute(sliceL,[1,3,2]);
                otherwise
                    sliceL = this.LData{labelidx}(:,:,planeIdx);
            end
        end
    end
    
    
    
    methods % Overloaded functions
        % Bear in mind that the underlying data is being changed, rather
        % than making a copy when no output is requested
        
        
        function himage = imshow(this,varargin)
            rgb = getDataRGB(this);
            himage = imshow(rgb,varargin{:});
        end
        
    end
end
