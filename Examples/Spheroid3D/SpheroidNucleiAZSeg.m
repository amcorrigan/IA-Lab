classdef SpheroidNucleiAZSeg < OneStageAZSeg
    % detect the nuclei within a 3D spheroid
    % Don't attempt to segment individual nuclei at this point, just detect
    % the centres
    properties
        SizeXY = 5;
        SizeZ = 2;
        Threshold = 1;
        BgScale = 2.2;
    end
    methods
        function this = SpheroidNucleiAZSeg(sizexy,sizez,thresh)
            
            this@OneStageAZSeg({'SizeXY','SizeZ','Threshold','BgScale'},...
                {'Size in XY','Size in Z','Intensity threshold','Background smoothing'},...
                [1,1,1.5,1],'Spheroid Nuclei Detection',1,0,1);
            
            if nargin>0 && ~isempty(sizexy)
                this.SizeXY = sizexy;
            end
            if nargin>0 && ~isempty(sizez)
                this.SizeZ = sizez;
            end
            
            if nargin>2 && ~isempty(thresh)
                this.Threshold = thresh;
            end
            
            
            this.ReturnType = 'point';
        end
        
        function outim = runStep1(this,im,labdata)
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            if this.BgScale>0
                bgim = gaussFiltND(im,this.BgScale*[this.SizeXY,this.SizeXY,this.SizeZ]);
                im = im - 0.8*bgim;
            end
            fim = dogFiltND(im,[this.SizeXY,this.SizeXY,this.SizeZ]);
            
            lmax = imregionalmax(fim);
            
            if nargin>2 && ~isempty(labdata)
                if iscell(labdata)
                    labdata = labdata{1};
                end
                lmax = lmax & (labdata>0);
            end
            
            
            outim = lmax.*fim; % this is ready to be thresholded
        end
    end
end