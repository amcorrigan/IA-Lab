classdef cPointLabelnC < cLabelInterface
    properties (Dependent)
        SizeX
        SizeY
        ImSize
        
    end
    properties
        Name
        XYZData % basic coordinate list (called xyz but doesn't have to be 3 dimensions)
        % change the name from the region label class so that we have to go
        % through methods to access them
        NumLabels = 0;
        
        NativeMap% default colour map when none is specified, like NativeColour for images
%         CMap_  % private cmap to stop MATLAB complaining about using other properties in the setting..
        NumChannel = 1;
        RPerm
        BorderXY = [];
        ImSize_;
        
        Marker = 'o';
    end
    methods
        function this = cPointLabelnC(xyz,imsiz)
            % for multichannel point storage, use a cell array
            if ~iscell(xyz)
                xyz = {xyz};
            end
            
            this.XYZData = xyz;
            
            this.ImSize_ = imsiz;
        end
        
        function xyz = rawdata(this)
            xyz = this.XYZData;
        end
        
        function L = getLabel2D(this)
            % return a label matrix populated with the points as labels
            
            L = cell(numel(this.XYZData),1);
            for ii = 1:numel(this.XYZData)
                rxy = round(this.XYZData{ii}(:,1:2));

                imsiz = this.ImSize_(1:2);

                rxy(rxy(:,1)<1 | rxy(:,1)>imsiz(1) | rxy(:,2)<1 | rxy(:,2)>imsiz(2),:) = [];

                inds = amcSub2Ind(imsiz,rxy);
                L{ii} = zeros(imsiz);
                L{ii}(inds) = (1:numel(inds))';
            end
        end
        
        function L = getLabel3D(this)
            % for now the 3D method is a proxy for N-D
            % return a label matrix populated with the points as labels
            L = cell(numel(this.XYZData),1);
            for ii = 1:numel(this.XYZData)
                rxy = round(this.XYZData{ii});

                imsiz = this.ImSize_;

                rxy(any(rxy<1,2) | any(bsxfun(@gt,rxy,imsiz),2),:) = [];

                inds = amcSub2Ind(imsiz,rxy);
                L{ii} = zeros(imsiz);
                L{ii}(inds) = (1:numel(inds))';
            end
        end
        
        function pHandles = showAnnotation(this,cmaps,parenth)
            % this method is specifically for a 2D visualization.
            % Therefore, we want to use the z for the colour if there is a
            % z, otherwise randomise?
            
            if ~iscell(cmaps)
                cmaps = {cmaps};
            end
            
            pHandles = cell(numel(this.XYZData),1);
            
            for ii = numel(pHandles):-1:1
                if ~isempty(this.XYZData{ii}) && ~(isscalar(cmaps{ii}) && isnan(cmaps{ii}))
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
                    
                    % unlike with the region-based visualisation, we don't
                    % need a separate graphics object for each identified
                    % point; they can be merged into, say, 20 colours
                    if size(this.XYZData{ii},2)<3
                        colind = ceil(20*rand(size(this.XYZData{ii},1),1));
                    else
                        colind = max(1,min(20,ceil(20*this.XYZData{ii}(:,3)/this.ImSize_(3))));
                    end
                    
                    for jj = 1:20
                        mapind = ceil(size(usemap,1)/20 * jj);
                        currinds = colind==jj;
                        if nnz(currinds)>0
                            xdata = this.XYZData{ii}(currinds,2);
                            ydata = this.XYZData{ii}(currinds,1);
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
        
        
        function val = get.SizeX(this)
            val = this.ImSize_(1);
        end
        function val = get.SizeY(this)
            val = this.ImSize_(2);
        end
        function val = get.ImSize(this)
            val = this.ImSize_;
        end
        
    end
end
