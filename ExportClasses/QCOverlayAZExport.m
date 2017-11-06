classdef QCOverlayAZExport < AZExport
    properties
        CMaps
        DoShuffle
        NativeColour
        
        ImIdx = Inf;
        LabIdx = Inf;
    end
    methods
        function this = QCOverlayAZExport(cmaps,doshuffle,imcolours,iminds,labinds)
            this.ExportType = 'Image';
            
            if nargin<2 || isempty(doshuffle)
                doshuffle = true;
            end
            if nargin<1 || isempty(cmaps)
                cmaps = {[0.5,0,0;1,0,0;1,0.5,0.5],...
                    [0,0.5,0;0,1,0;0.5,1,0.5],...
                    [0,0,0.5;0,0,1;0.5,0.5,1],...
                    [1,1,1],...
                    [0,1,1]}; % this'll do for now..
            end
            
            this.CMaps = cmaps;
            this.DoShuffle = doshuffle;
            
            % other settable parameters should be the contrast adjustment
            % of the underlying image - otherwise it could be completely
            % black or white in the output
            % for now, just use a quantile
            if nargin<3 || isempty(imcolours)
                imcolours = num2cell([1,0,0;0,1,0;0,0,1;1,1,1],2);
            end
            
            if nargin>3 && ~isempty(iminds)
                this.ImIdx = iminds;
            end
            if nargin>4 && ~isempty(labinds)
                this.LabIdx = labinds;
            end
                
            
            this.NativeColour = imcolours;
            
        end
        
        function export(this,labdata,imdata,filename)
            if ~any(isinf(this.ImIdx))
                imdata = imdata(this.ImIdx);
            end
            if ~any(isinf(this.LabIdx))
                labdata = labdata(this.LabIdx);
            end
            
            
            
            rgb = zeros(size(imdata{1},1),size(imdata{1},2),3);
            for ii = 1:numel(imdata)
                % the scale and hence the control parameters depend on the
                % image
                
                % For this export, the image needs to be 2D
                if size(imdata{ii},3)>1
                    imdata{ii} = max(imdata{ii},[],3);
                end
                
                b = quantile(double(imdata{ii}(:)),1-0.005);
                a = quantile(double(imdata{ii}(:)),0.005);

                fim = (double(imdata{ii}) - a)/(b-a);
                
                
                rgb = max(rgb,bsxfun(@times,fim,reshape(this.NativeColour{ii},[1,1,3])));
            end
            
            % then the regions need overlaying
            % use labelOverlay - but this needs to be debugged for when
            % there are holes or touching regions
            fig = figure('Visible','off');
            ax = axes('activepositionproperty','position','position',[0,0,1,1],'parent',fig);
            imshow(rgb)
            hold on
            for jj = 1:numel(labdata)
                usemap = this.CMaps{mod(jj-1,numel(this.CMaps))+1};
                
                if size(labdata{jj},2)>3
                    temphandle = labelOverlay(labdata{jj},usemap,[],[],true,ax);
                else
                    maxz = max(cellfun(@(x)size(x,3),imdata));
                    temphandle = pointOverlay(labdata{jj},usemap,ax,maxz,'o'); 
                end
            end
            set(fig,'paperunits','centimeters')
            set(fig,'paperposition',[2 2 12 10]) % the aspect ratio should be determined by the image shape
            set(fig,'color','w')
            
            % need to check that the folder exists before writing to it
            outfol = fileparts(filename);
            if exist(outfol,'dir')==0
                mkdir(outfol)
            end
            
            print(fig,'-dpng','-r400',filename) % the resolution should also be taken care of by the class properties
            close(fig)
            
        end
    end
end
