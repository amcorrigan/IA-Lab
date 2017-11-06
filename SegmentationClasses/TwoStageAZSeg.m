classdef TwoStageAZSeg < AZSeg
    % Sub class for segmentation cases which can be logically separated into two
    % stages, so that the paramter tuning can be done interactively.
    %
    % By inheriting from AZSeg, the normal all in one parameter tuning can still be
    % done, but this adds some extra options.
    properties (SetAccess = protected)
%         Params
%         Labels
        StageIdx % add a stage index for each of the parameters
        % this is used for the interactive step, to determine which parameters
        % should be tuned at which stage
        % integer index (eg 1,2) means that the parameter forms part of that step
        % half integer (eg 1.5, 2.5) means that the parameter is a threshold which
        % can be applied at the end of the stage.  This is worth flagging because
        % it means that the threshold can be interactively tuned without having to
        % run the whole step again.
        % don't think that the half-integer index is required except at the
        % start, because we directly storing the threshold parameters
        % below.

        ThreshInd = [NaN; NaN];
        
        NumSteps = 2;
        
        DoLabelling = true;
    end
    methods
        function this = TwoStageAZSeg(params,labels,stageidx,varargin)
            this = this@AZSeg(params,labels,varargin{:});

            this.StageIdx = stageidx;
            % some setup steps to ensure that the parameters are correct
            ind1 = find(this.StageIdx>1 & this.StageIdx<2);
            if numel(ind1)>1
                error('Only one threshold can be flagged per stage')
            end
            if ~isempty(ind1)
                this.ThreshInd(1) = ind1;
            end
            ind2 = find(this.StageIdx>2 & this.StageIdx<3);
            if numel(ind2)>1
                error('Only one threshold can be flagged per stage')
            end
            if ~isempty(ind2)
                this.ThreshInd(2) = ind2;
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
            
            fim = this.applyThreshold(fim,1);
            
            fim = this.runStep2(im,fim,L);
            
            if ~isnan(this.ThreshInd(2))
                fim = this.applyThreshold(fim,2);
            end
            if this.DoLabelling
                Lout = this.applyLabelling(fim);
            else
                % labelling has already been applied
                Lout = fim;
            end
        end

        % These need to called from outside if we want to tune interactively (don't
        % know in advance how many images there will be)
        fim = runStep1(this,im,L);
        
        function fim = applyThreshold(this,fim,step)
            if isnan(this.ThreshInd(step))
                return
            end
            
            if iscell(fim)
                % if more than one intermediate image, only apply threshold
                % to the first one
                fim{1} = fim{1}>=this.(this.Params{this.ThreshInd(step)});
            else
                if ~isnan(this.ThreshInd(step))
                    fim = fim>=this.(this.Params{this.ThreshInd(step)});
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

        function Lout = runStep2(this,im,fim,L)
            % perhaps a better interface would be to pass all the images as
            % a cell array in the second input?  Will work as long as this
            % is reflected in the process method above
            % By doing it this way, we'll need to know how many images are
            % returned by each stage
            % This can be held internally
            
            % have no second step by default
            Lout = im{end};
        end
        
        function argout = runStep(this,step,im,fim,L)
            if nargin<4 || isempty(fim)
                fim = []; % make sure it's an empty numeric array
            end
            if nargin<5 || isempty(L)
                L = []; % is empty array or cell more appropriate?
            end
            switch step
                case 1
                    argout = runStep1(this,im,L);
                case 2
                    argout = runStep2(this,im,fim,L);
                otherwise
                    error('Step must be 1 or 2')
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
        
% %         % should be possible to define this generically
% %         function SettingsObj = defaultSettingsUI(this,parenth)
% %             % need to return a fully populated SettingsAdjuster object
% %             [pvals,labels] = getValuesLabels(this);
% %             
% %             SettingsObj = SettingsAdjuster(parenth,labels,pvals);
% %         end
        

    end
end
