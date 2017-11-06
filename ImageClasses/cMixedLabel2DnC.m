classdef cMixedLabel2DnC < cLabel2DnC
    % label class allowing different types of labels (eg regions, points)
    % for the different channels
    
    % most of the behaviour can be inherited from cLabel2DnC I think
    properties
        LabelType = {};
        Marker = 'o';
    end
    methods
        function this = cMixedLabel2DnC(ldata,imsize,cmap)
            
            if nargin<3
                cmap = [];
            end
            
            this = this@cLabel2DnC(ldata,cmap);
            
            % try to autodetect the type of label
            for ii = 1:this.NumChannel
                if size(this.LData{ii},2)<5
                    this.LabelType{ii} = 'point';
                    
                    % the number of labels needs correcting here, because
                    % it's not a label matrix
                    this.NumLabels(ii) = size(this.LData{ii},1);
                    
                else
                    this.LabelType{ii} = 'region';
                    
                end
            end
            
            % only use the supplied size if all the labels are points
            ind1 = find(strcmpi('region',this.LabelType),1,'first');
            
            if ~isempty(ind1)
                imsize = size(this.LData{ind1});
            end
            
            this.setLabelSize(imsize);
            
            % also regenerate the random permutations, using the correct
            % sizes and numbers
            this.generateRPerm();
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
                    if strcmpi(this.LabelType{ii},'region')
                        try
                        this.BorderXY{ii} = label2outline(L{ii},skip,interpfact);
                        catch ME
                            rethrow(ME)
                        end
                    else
                        this.BorderXY{ii} = this.LData{ii}; % this might not actually be necessary, but leave here for possible output
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
                        
                        if strcmpi(this.LabelType{ii},'region')
                            for jj = 1:numel(borderXY{ii})
                                % take the nearest colour
                                colidx = 1 + ceil((size(usemap,1)-1)*(jj-1)/(max(numel(borderXY{ii}),2)-1));
                                col = usemap(colidx,:);
                                pHandles{ii}(jj) = patch('xdata',borderXY{ii}{jj}(:,2),'ydata',borderXY{ii}{jj}(:,1),...
                                    'edgecolor',col,'facecolor',col,'parent',parenth,...
                                    'linewidth',1.5,'facealpha',0.1);
                            end
                        else
                            % unlike with the region-based visualisation, we don't
                            % need a separate graphics object for each identified
                            % point; they can be merged into, say, 20 colours
% %                             if size(this.LData{ii},2)<3
                                colind = ceil(20*rand(size(this.LData{ii},1),1));
% %                             else
% %                                 colind = max(1,min(20,ceil(20*this.LData{ii}(:,3)/this.ImSize(3))));
% %                             end

                            for jj = 1:20
                                mapind = ceil(size(usemap,1)/20 * jj);
                                currinds = colind==jj;
                                if nnz(currinds)>0
                                    xdata = this.LData{ii}(currinds,2);
                                    ydata = this.LData{ii}(currinds,1);
                                else
                                    xdata = NaN;
                                    ydata = NaN;
                                end
                                pHandles{ii}(jj) = line('parent',parenth,'xdata',xdata,...
                                        'ydata',ydata,'marker',this.Marker,'color',usemap(mapind,:),...
                                        'markersize',4,'linestyle','none');
                            end

                        end
                    end
                end
            end
        end
        
        function sliceL = getSlice(this,sliceaxis,planeIdx,labelidx)
            if nargin<4 || isempty(labelidx)
                labelidx = 1;
            end
            
            if strcmpi(this.LabelType{labelidx},'region')
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
            else
                % easiest way is to build the label matrix then slice, but
                % there might be a quicker way in the long run..
                
                tempL = zeros(this.ImSize);
                
                sxyz = round(this.LData{labelidx});
                sxyz = max(sxyz,1);
                sxyz = bsxfun(@min,sxyz,this.ImSize);
                
                tempL(amcSub2Ind(this.ImSize,sxyz)) = (1:size(sxyz,1))';
                
                % might want to dilate a little bit too?
                if this.ImSize(3)>1
                    el = diamondElement3D(1);
                else
                    el = diamondElement(1);
                end
                tempL = imdilate(tempL,el);
                
                switch lower(sliceaxis)
                    case 'x'
                        sliceL = tempL(planeIdx,:,:);
                        sliceL = permute(sliceL,[3,2,1]);
                    case 'y'
                        sliceL = tempL(:,planeIdx,:);
                        sliceL = permute(sliceL,[1,3,2]);
                    otherwise
                        sliceL = tempL(:,:,planeIdx);
                end
            end
        end
    end
end
