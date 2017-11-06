classdef ComparisonImageAZExport < AZExport
    % Standard export of QC images with segmentation overlaid over the
    % original image
    % it would be good to be able to set the style, such as line thickness,
    % area transparency, etc, within this class, to save having to write
    % different ones for each style
    properties
        LabelColour
        NativeColour
        
        ImIdx = Inf;
        LabIdx = Inf;
        
        LineThickness = 1;
        AreaAlpha = 0;
        
        ScaleFunc = [];
    end
    methods
        function this = ComparisonImageAZExport(iminds,labinds,imcolours,labcolours,scalefunc)
            this.ExportType = 'image';
            if nargin>0 && ~isempty(iminds)
                this.ImIdx = iminds;
            end
            if nargin>1 && ~isempty(labinds)
                this.LabIdx = labinds;
            end
            
            if nargin<3 || isempty(imcolours)
                tempcolours = {[1,0,0];[0,1,0];[0,0,1]};
                
                imcolours = tempcolours(mod(((1:numel(this.ImIdx))-1),numel(tempcolours))+1);
                
            end
            
            if nargin<4 || isempty(labcolours)
                tempcolours = {[1,1,1];[1,1,0];[0,1,1];[1,0,1]};
                
                labcolours = tempcolours(mod(((1:numel(this.LabIdx))-1),numel(tempcolours))+1);
            end
            
            if ~iscell(imcolours)
                imcolours = {imcolours};
            end
            if ~iscell(labcolours)
                labcolours = {labcolours};
            end
            
            this.NativeColour = imcolours;
            this.LabelColour = labcolours;
            
            if nargin>4 && ~isempty(scalefunc)
                this.ScaleFunc = scalefunc;
            end
        end
        
        function varargout = setLineThickness(this,thickval)
            this.LineThickness = thickval;
            if nargout>0
                varargout{1} = this;
            end
        end
        function varargout = setAreaAlpha(this,alphaval)
            this.AreaAlpha = alphaval;
            
            if nargout>0
                varargout{1} = this;
            end
        end
        
        function varargout = setClipLimit(this,cliplimit)
            this.ClipLimit = cliplimit;
            
            if nargout>0
                varargout{1} = this;
            end
        end
        
        
        function export(this,labdata,imdata,filename)
            
            if ~iscell(labdata)
                labdata = {labdata};
            end;
            
            
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
                
% %                 % is this very slow?
% %                 b = quantile(double(imdata{ii}(:)),1-this.ClipLimit);
% %                 a = quantile(double(imdata{ii}(:)),this.ClipLimit);
% % 
% %                 fim = (double(imdata{ii}) - a)/(b-a);   
                if ~isempty(this.ScaleFunc)
                    fim = this.ScaleFunc(imdata{ii});
                else
                    fim = imdata{ii};
                end
                
                
                rgb = max(rgb,bsxfun(@times,fim,reshape(this.NativeColour{ii},[1,1,3])));
            end
            
            % now do the overlays
            
            for ii = 1:numel(labdata)
                
                if size(labdata{ii},1)>0
                    if size(labdata{ii},2)>3
                        bw = (labdata{ii}>0) & (imerode(labdata{ii},diamondElement(this.LineThickness))==0);
                    else
                        bw = false(size(rgb,1),size(rgb,2));
                        bw(amcSub2Ind(size(bw),labdata{ii}(:,1:2))) = true;
                    end
                else
                    bw = false(size(rgb,1),size(rgb,2));
                end
                
                
                rgb = imoverlay(rgb,bw,this.LabelColour{ii},1);
            end
            
            % imwrite won't create the folder by itself, so need to check
            % for that here
            [a,b] = fileparts(filename);
            if ~isempty(a) && ~exist(a,'dir')
                mkdir(a)
            end
            
            imwrite(rgb,filename);
        end
    end
end
