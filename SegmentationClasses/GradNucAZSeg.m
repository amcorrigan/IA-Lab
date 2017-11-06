classdef GradNucAZSeg < TwoStageAZSeg
    % Nuclear segmentation - finding regional maxima and separating them using gradient watershed.
    properties
        NucRadius = 10;
        RelThresh = 0.2;
        
        DistanceWeight1 = 5e-3;
        DistanceWeight2 = 0.01;
    end
    methods
        function this = GradNucAZSeg(nucrad,thr,dweight1,dweight2)
            this = this@TwoStageAZSeg(...
                {'NucRadius','RelThresh','DistanceWeight1','DistanceWeight2'},...
                {'Nucleus detection','Threshold','Boundary effect','Centre effect'},...
                [1,1.5,2,2],'Clustered nucleus detection',1,0,1);
            
            if nargin>0 && ~isempty(nucrad)
                this.NucRadius = nucrad;
            end
            if nargin>1 && ~isempty(thr)
                this.RelThresh = thr;
            end
            if nargin>2 && ~isempty(dweight1)
                this.DistanceWeight1 = dweight1;
            end
            if nargin>3 && ~isempty(dweight2)
                this.DistanceWeight2 = dweight2;
            end
            
            
        end
        
        % step 1 is to do the equalisation, find the regional maxima 
        % and precalculate all the
        % distance transforms for a more responsive stage 2 adjustment
        function fim = runStep1(this,im,~)
            
            if iscell(im)
                im = im{1};
            end
            
            J = adapthisteq(rangeNormalise(im),'numtiles',[16,16],'cliplimit',0.05);
            S = steptrans(J,diskElement(2.5,1),12);
            
            smoothSize = this.NucRadius/5 * [1,1];
            fg = bwmorph(imregionalmax(gaussFiltND(S,smoothSize)) & J>0.2,'shrink',Inf);
            
            D2 = bwdist(fg);
            
            imoc = openCloseByRecon(J,diskElement(this.NucRadius/3));
            gg = gaussGradient2D(imoc,2);
            
            % D1 has to come after thresholding.
            
            fim = {J,fg,D2,gg}; % the first element, J, will get thresholded
        end
        
        % step2 is to 
        function L = runStep2(this,~,fim,~,~)
            % what are these extra inputs? One is preexisting label matrix,
            % it might be possible to integrate this into the fim to save
            % the label being passed if it isn't needed any more..
            
            % I think reassigning here won't use any extra memory..?
            bw = fim{1};
            fg = fim{2};
            D2 = fim{3};
            gg = fim{4};
            
            D1 = bwdist(~bw);
            bg = imerode(~bw,true(7)); % would this be better a little bit bigger?
            gradim = gg - this.DistanceWeight1*D1 + this.DistanceWeight2*D2;
            L = markerWatershed(gradim,fg,bg);
            
            % if we want, we can also output the regional maxima
            % coordinates, as these might be more accurate for reading off
            % intensities later in the workflow.
        end
    end
    
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of clustered nuclei','',...
                ['Detect nuclei that tend to be quite small and clustered.',...
                ' Equalisation and morphological maxima-finding, followed by ',...
                'marker-based gradient thresholding']};
        end
    end
end