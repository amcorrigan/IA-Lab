classdef TwoStageSeedAZSeg < AZSeg
    % two stages of segmentation, for instance nuclei segmentation followed
    % by cell segmentation
    %
    % The idea is to combine the two steps into a single module, and allow
    % all parameters to be adjusted simultaneously
    % If this is possible, could extend to multiple levels, but is it worth
    % it?
    
    properties
        PrimarySegObj
        SecondarySegObj
        
        NumPrimParams
        NumSecParams
        
%         NumInputChan
%         NumOutputChan
    end
    methods
        function this = TwoStageSeedAZSeg(prim,sec)
            % each of these classes will already have defined it's
            % parameters and labels, so we have to extract them
            % modify the labels to reflect the
            % primary and secondary status
            
            plabels = cellfun(@(x)['Primary ' x],prim.Labels,'uniformoutput',false);
            slabels = cellfun(@(x)['Secondary ' x],sec.Labels,'uniformoutput',false);
            
            this = this@AZSeg([prim.Params,sec.Params],[plabels,slabels]);
            this.NumPrimParams = numel(prim.Params);
            this.NumSecParams = numel(sec.Params);
            
            this.PrimarySegObj = prim;
            this.SecondarySegObj = sec;
            
        end
        
        % need to override updateSettings and getValuesLabels for accessing
        % the nested values
        
        function [pvals,labels] = getValuesLabels(this)
            pvals = zeros(numel(this.Params),1);
            for ii = 1:this.NumPrimParams
                pvals(ii) = this.PrimarySegObj.(this.Params{ii});
            end
            for ii = (this.NumPrimParams + (1:this.NumSecParams))
                try
                pvals(ii) = this.SecondarySegObj.(this.Params{ii});
                catch ME
                    rethrow(ME)
                end
            end
            
            
            if ~isempty(this.Labels)
                labels = this.Labels;
            else
                labels = this.Params;
            end
        end
        
        function updateSettings(this,values)
            if isa(values,'SettingsAdjuster')
                values = values.Values;
            end
            
            for ii = 1:min(numel(values),this.NumPrimParams)
                this.PrimarySegObj.(this.Params{ii}) = values(ii);
            end
            for ii = (this.NumPrimParams + (1:min(numel(values)-this.NumPrimParams,this.NumSecParams)))
                this.SecondarySegObj.(this.Params{ii}) = values(ii);
            end
            
            
        end
        
        function [L,interIm] = process(this,imData,~,keepIntermed)
            % two stages
            % how do we decide which channels are used for which
            % segmentation? This comes from the NumInputChan property of
            % the segmentation methods.
            
            % the number of channels in imData (ie number of cell elements)
            % should be equal to the sum of the NumInputChan properties
            % (even if this requires duplication of channels used for
            % both..)
            
            L = cell(this.NumOutputChan,1);
            
            outchan1 = 1:this.PrimarySegObj.NumOutputChan;
            inchan1 = 1:this.PrimarySegObj.NumInputChan;
            
            outchan2 = this.PrimarySegObj.NumOutputChan + (1:this.SecondarySegObj.NumOutputChan);
            inchan2 = this.PrimarySegObj.NumInputChan + (1:this.SecondarySegObj.NumInputChan);
            
            L(outchan1) = process(this.PrimarySegObj,imData(inchan1));
            
            temp = process(this.SecondarySegObj,imData(inchan2),L(outchan1));
            
            if ~iscell(temp)
                temp = {temp};
            end
            L(outchan2) = temp;
            
        end
        
        function N = getNumInputs(this)
            N = this.PrimarySegObj.NumInputChan + this.SecondarySegObj.NumInputChan;
        end
        
        function N = getNumOutputs(this)
            N = this.PrimarySegObj.NumOutputChan + this.SecondarySegObj.NumOutputChan;
        end
    end
end
