classdef MicroNucleiAZSeg < TwoStageAZSeg
    % Detect micronuclei, separate from the main nucleus
    %
    % Interesting features are size and relative DNA content compared to
    % the main nucleus, so it's best to get a label matrix rather than just
    % coordinates
    
    properties
        Threshold = 0.1;
        SizeLimit = 20;
    end
    methods
        function this = MicroNucleiAZSeg(thresh,sizelim)
            this@TwoStageAZSeg({'Threshold','SizeLimit'},{'Detection Threshold','Maxmimum Size'},...
                [1.5,2],'MicroNuclei Detection',1,2,2);
            
            if nargin>0 && ~isempty(thresh)
                this.Threshold = thresh;
            end
            if nargin>1 && ~isempty(sizelim)
                this.SizeLimit = sizelim;
            end
            
            % the labelling is already taken care of in step 2
            this.DoLabelling = false;
        end
        function fim = runStep1(this,imdata,labdata)
            if iscell(imdata)
                imdata = imdata{1};
            end
            
            J = adapthisteq(mat2gray(double(imdata)),'numtiles',[8,8],'cliplimit',0.003);
            
            if ~iscell(labdata)
                labdata = {labdata};
            end
            
            marker = J;
            marker(labdata{1}==0) = 0;
            recim = imreconstruct(marker,J);
            microim = J-recim;
            
            % this will miss objects that are very close to the nuclei
            
            if numel(labdata)>1
                microim(labdata{2}==0)=0;
            end
            
            % need a threshold value for what constitutes a micronucleus
            fim = {microim};
        end
        
        function L = runStep2(this,~,fim,~)
            bw = fim{1};
            
            % just have to apply the size threshold here, some of the
            % objects are likely to be full nuclei that were missed the
            % first time round
            % Might be an option to add these in as additional nuclei, but
            % then the cytoplasm part would need rerunning too..
            % Output it anyway for now...
            
            bw2 = bwareafilt(bw,[0,this.SizeLimit]);
            
            L{1} = bwlabeln(bw2);
            
            L{2} = bwlabeln(bw & ~bw2);
        end
    end
end
