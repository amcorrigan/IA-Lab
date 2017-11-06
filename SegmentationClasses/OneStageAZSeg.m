classdef OneStageAZSeg < AZSeg
    % sub class for a single stage of segmentation, with a possible
    % threshold at the end
    % keep as image based for now, but in the future this will allow point
    % based as well as region based segmentation measurements.
    properties
        ThreshInd = NaN;
        NumSteps = 1;
        
        StageIdx
    end
    methods
        function this = OneStageAZSeg(params,labels,stageidx,varargin)
            this = this@AZSeg(params,labels,varargin{:});

            this.StageIdx = stageidx;
            % some setup steps to ensure that the parameters are correct
            ind1 = find(this.StageIdx>1 & this.StageIdx<2);
            if numel(ind1)>1
                error('Only one threshold can be flagged per stage')
            end
            if ~isempty(ind1)
                this.ThreshInd = ind1;
            end
            
        end

        function [Lout,im,extradata] = process(this,im,L)
            % this might not be as general as is possible, but start with the most
            % likely use cases
            if nargin<3
                L = [];
            end
            
            extradata = [];
            
            fim = this.runStep1(im,L);
            if ~isnan(this.ThreshInd(1))
                fim = this.applyThreshold(fim);
            end
            
            % then apply the labelling - this will depend on the output
            % style for the segmentation method - region or point
            % but the setup should also allow for sub-pixel refinement of
            % the coordinates within the specific segmentation method
            
            % instead of this here, use a separate method which can be
            % overridden
%             Lout = bwlabeln(fim);
            Lout = this.applyLabelling(fim);
        end
        
        % These need to called from outside if we want to tune interactively (don't
        % know in advance how many images there will be)
        fim = runStep1(this,im,L);
        
        function fim = applyThreshold(this,fim)
            if isnan(this.ThreshInd(1))
                return
            end
            
            if iscell(fim)
                % if more than one intermediate image, only apply threshold
                % to the first one - THIS SHOULD NEVER HAPPEN FOR THE ONE
                % STEP SEGMENTATION
                fim{1} = fim{1}>=this.(this.Params{this.ThreshInd(1)});
            else
                if ~isnan(this.ThreshInd(1))
                    fim = fim>=this.(this.Params{this.ThreshInd(1)});
                end
            end
        end
        
        function Lout = applyLabelling(this,fim)
            % try to be general here - this can always be overridden by a
            % specific segmentation algorithm
            
            if iscell(fim)
                fim = fim{1}; % this shouldn't really happen for the last step 
            end
            
            switch lower(this.ReturnType)
                case 'region'
                    Lout = bwlabeln(fim);
                case 'point'
                    Lout = findn(fim);
                otherwise
                    error('Unknown return type for segmentation')
            end
            
        end

        
        function argout = runStep(this,step,im,~,L)
            
            if nargin<5 || isempty(L)
                L = []; % is empty array or cell more appropriate?
            end
            switch step
                case 1
                    argout = runStep1(this,im,L);
                otherwise
                    error('Step must be 1')
            end
        end
        
        function fim = preVisProcessing(this,fim)
            % optional preprocessing of the output to make it more easily
            % visualized
            % eg dilation of local maxima
            
            % Important to note, if there is a threshold, this will be
            % applied before the threshold (so that it only needs doing
            % once).  This mya limit the things that can be applied here
            
            % Leave empty for prototype
        end
        
        % should be possible to define this generically
        function SettingsObj = defaultSettingsUI(this,parenth)
            % need to return a fully populated SettingsAdjuster object
            [pvals,labels] = getValuesLabels(this);
            
            SettingsObj = SettingsAdjuster(parenth,labels,pvals);
        end
        

    end
end