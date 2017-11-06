classdef AnnotatedDisplay3DnC < Display3DnC
    % 3D QC display
    %
    % TO DO - add the label colourmaps back to the class and GUI, rather
    % than using jet all the time..
    
    properties
%         ApplyChangesButton
        
        LabelShowSlider
        
        RawData
        AnnoData % shall we store these and pass each one to ImData when we switch? 
    end
    methods
        function this = AnnotatedDisplay3DnC(varargin)
            this = this@Display3DnC(varargin{:});
        end
        
        function varargout = showImage(this,imObj)
            if nargin>1
                this.ImObj = imObj;
            end
            
            hh = showImage@Display3DnC(this);
            
            if nargout>0
                varargout{1} = hh;
            end
            
        end
        
        function setupDisplay(this)
            setupDisplay@Display3DnC(this);
            
            
            % then add the transparency slider
            % this isn't quite in the right place yet!
            parenth = get(this.SliderX,'parent');
            this.LabelShowSlider = uicontrol('style','slider','parent',parenth,...
                'max',1,'min',0,'value',0.5,'callback',@(src,evt)this.showImage);
            
        end
        
        function populateCMaps(this)
            % populate the default colourmap with the image objects
            % native colour
            this.ColourMaps = cell(this.ImObj.ImObj.NumChannel,1);

            % this is where the current maps will be stored - empty
            % means recalculate
            this.UseMaps = cell(this.ImObj.ImObj.NumChannel,1);

            for ii = 1:numel(this.ColourMaps)
                this.ColourMaps{ii} = [this.ImObj.getNativeColour(ii),this.BuiltInMaps(:)'];
                this.CurrMap(ii) = 1; % use native colour.
            end
            
            % populate the label colourmaps here
            
        end

        
        function [cdataxy,cdataxz,cdatayz] = calculateImage(this,dimstr)
            % data is returned as cell array of double, which should be
            % fine for contrast adjustment
            %-- maybe save the pdata as artributes.
            %-- To do: how to invert colour
            
            cdataxy = [];
            cdataxz = [];
            cdatayz = [];
            
            if nargin<2 || isempty(dimstr)
                dimstr = 'xyz'; % update all by default
                % alternatively, a difference between CurrXYZ and the
                % slider values could be used as an automatic flag to
                % update the panel - is this robust enough?
            end
            
            % rewritten so that it's the colourmap that has the contrast
            % adjustment applied, rather than the image..
            % This is almost fast enough without storing the individual
            % channels, but it could be done so that the individual
            % testmaps are stored and then marked as dirty if they need to
            % be recalculated, eg by colourcallback

            this.ImData = this.ImObj.getDataC3D(); % we should ensure that this method returns a uint16 array
% %             frac = get(this.LabelShowSlider,'Value');
% %             this.ImData = frac*this.RawData + (1-frac)*this.AnnoData;
            this.ImSizes = cell2mat(cellfun(@(x)[size(x,1),size(x,2),size(x,3)],this.ImData,'uni',false));
            
            % examine the z-sizes to make sure that they're all the same
            % size - if they're not calculate the nearest slice to use in
            % each case
            maxZ = max(this.ImSizes(:,3));
            this.UseZInds = max(1,ceil(bsxfun(@times,this.ImSizes(:,3),linspace(0,1,maxZ))));
            
            
            this.ViewSize = [min(this.ImSizes(:,1)),min(this.ImSizes(:,2)),max(this.ImSizes(:,3))];
            % this is currently different to the 2D version, which trims
            % around the edge of images which are larger than the rest
            
            if isempty(this.CurrXYZ)
                
                this.CurrXYZ = ceil(this.ViewSize/2);

                set(this.SliderZ,'min',1,'max',this.ViewSize(3),'Value',this.CurrXYZ(3),...
                    'callback',@this.sliderZCallback,'sliderstep',[1,5]/this.ViewSize(3))
                set(this.SliderY,'min',1,'max',this.ViewSize(2),'Value',this.CurrXYZ(2),...
                    'callback',@this.sliderYCallback,'sliderstep',[1/this.ViewSize(2),0.05])
                set(this.SliderX,'min',1,'max',this.ViewSize(1),'Value',this.CurrXYZ(1),...
                    'callback',@this.sliderXCallback,'sliderstep',[1/this.ViewSize(1),0.05])

            end

            % want to separate the cdata into three separate method calls, so that
            % when the slice is changed, they can be updated individually
            if strfind(dimstr,'z')
                cdataxy = this.calculateXYData(); % pass imdata and imsizes rather than getting them each time
            end
            if strfind(dimstr,'y')
                cdataxz = this.calculateXZData();
            end
            if strfind(dimstr,'x')
                cdatayz = this.calculateYZData();
            end

        end

        function cdataxy = calculateXYData(this)
            rawxy = calculateXYData@Display3DnC(this);
            
            % then get the sliced label array and calculate the colours
            
            % don't reference Label object properties directly, these
            % should be called by a method so that point labels can work
            % too..
            
            % why is this LData{1} and not iterating through all of them?
            % think at the moment this will only work for single label
            % classes (rather than nuclei, cyto, etc)
            % But in theory it could work for multiple, just needs
            % overlaying in order..
            
%             sliceL = this.ImObj.LabelObj.LData{1}(:,:,this.CurrXYZ(3));
            
            try
            sliceL = this.ImObj.LabelObj.getSlice('z',this.CurrXYZ(3),1);
            catch ME
                rethrow(ME)
            end
            
            indL = sliceL>0;
            % use the RPerm stored in the label matrix
            vals = this.ImObj.LabelObj.RPerm{1};
            
            cmap = 255*jet(this.ImObj.LabelObj.NumLabels);
            
%             rgb = ind2rgb(vals(sliceL(indL)),jet(this.ImObj.LabelObj.NumLabels));
            
            frac = get(this.LabelShowSlider,'value');
            
            rr = cmap(vals(sliceL(indL)),1);
            temp1 = double(rawxy(:,:,1));
            temp1(indL) = rr*frac + temp1(indL)*(1-frac);
            
            gg = cmap(vals(sliceL(indL)),2);
            temp2 = double(rawxy(:,:,2));
            temp2(indL) = gg*frac + temp2(indL)*(1-frac);
            
            bb = cmap(vals(sliceL(indL)),3);
            temp3 = double(rawxy(:,:,3));
            temp3(indL) = bb*frac + temp3(indL)*(1-frac);
            
            cdataxy = uint8(cat(3,temp1,temp2,temp3));
            
        end


        function cdataxz = calculateXZData(this)
            rawxz = calculateXZData@Display3DnC(this);
            
            % then get the sliced label array and calculate the colours
%             sliceL = this.ImObj.LabelObj.LData{1}(:,this.CurrXYZ(2),:);
%             sliceL = permute(sliceL,[1,3,2]);
            sliceL = this.ImObj.LabelObj.getSlice('y',this.CurrXYZ(2),1);
            
            indL = sliceL>0;
            % use the RPerm stored in the label matrix
            vals = this.ImObj.LabelObj.RPerm{1};
            
            cmap = 255*jet(this.ImObj.LabelObj.NumLabels(1));
            
%             rgb = ind2rgb(vals(sliceL(indL)),jet(this.ImObj.LabelObj.NumLabels));
            
            frac = get(this.LabelShowSlider,'value');
            
            rr = cmap(vals(sliceL(indL)),1);
            temp1 = double(rawxz(:,:,1));
            temp1(indL) = rr*frac + temp1(indL)*(1-frac);
            
            gg = cmap(vals(sliceL(indL)),2);
            temp2 = double(rawxz(:,:,2));
            temp2(indL) = gg*frac + temp2(indL)*(1-frac);
            
            bb = cmap(vals(sliceL(indL)),3);
            temp3 = double(rawxz(:,:,3));
            temp3(indL) = bb*frac + temp3(indL)*(1-frac);
            
            cdataxz = uint8(cat(3,temp1,temp2,temp3));
            
        end


        function cdatayz = calculateYZData(this)
            rawyz = calculateYZData@Display3DnC(this);
            
            % then get the sliced label array and calculate the colours
% %             sliceL = this.ImObj.LabelObj.LData{1}(this.CurrXYZ(1),:,:);
% %             sliceL = permute(sliceL,[3,2,1]);
            sliceL = this.ImObj.LabelObj.getSlice('x',this.CurrXYZ(1),1);
            
            indL = sliceL>0;
            % use the RPerm stored in the label matrix
            vals = this.ImObj.LabelObj.RPerm{1};
            
            cmap = 255*jet(this.ImObj.LabelObj.NumLabels);
            
%             rgb = ind2rgb(vals(sliceL(indL)),jet(this.ImObj.LabelObj.NumLabels));
            
            frac = get(this.LabelShowSlider,'value');
            
            rr = cmap(vals(sliceL(indL)),1);
            temp1 = double(rawyz(:,:,1));
            temp1(indL) = rr*frac + temp1(indL)*(1-frac);
            
            gg = cmap(vals(sliceL(indL)),2);
            temp2 = double(rawyz(:,:,2));
            temp2(indL) = gg*frac + temp2(indL)*(1-frac);
            
            bb = cmap(vals(sliceL(indL)),3);
            temp3 = double(rawyz(:,:,3));
            temp3(indL) = bb*frac + temp3(indL)*(1-frac);
            
            cdatayz = uint8(cat(3,temp1,temp2,temp3));
            
        end

        
%         function setupCData(this)
%             % from the annotated image object, precalculate the 4D rgb
%             % arrays for normal image and annotated.
%             %
%             % This is the only place where the contrast adjustment should
%             % be used, because the 4D calculation is very slow
%             
%             this.RawData = 
%             this.AnnoData = visualise3DLabels(L,im,shuff,1)
%         end
        

%         function applyChangesCallback(this,src,evt)
%             
%         end
        
    end
end
