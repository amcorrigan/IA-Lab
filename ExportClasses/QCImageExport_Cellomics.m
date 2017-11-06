classdef QCImageExport_Cellomics < QCImageAZExport
    % Standard export of QC images with segmentation overlaid over the
    % original image
    % it would be good to be able to set the style, such as line thickness,
    % area transparency, etc, within this class, to save having to write
    % different ones for each style
    methods
        function this = QCImageExport_Cellomics(iminds,labinds,imcolours,labcolours)
            
            this = this@QCImageAZExport(iminds,labinds,imcolours,labcolours);
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
            
            b = imfill(imdata{1} == 1, 'holes');
            g = imdata{1} == 3;
            r = imfill(imdata{1} == 4, 'holes') & ~b;
            
            rgb = double(cat(3, r, g, b));
            rgb = imoverlay(rgb,imfill(imdata{1} == 2, 'holes'), [0.4 0.4 0.4], 1);
            
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
