classdef TouchingEdgeAZMeasure < AZMeasure
    % How much of each label is touching the border of the image.
    % Default to 2D only for now..
    properties
        Detail = 1;
    end
    methods
        function this = TouchingEdgeAZMeasure(propPrefix,detaillevel)
            this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(detaillevel)
                this.Detail = detaillevel;
            end
            
        end
        
        function [stats,varargout] = measure(this,labdata,~)
            if iscell(labdata)
                labdata = labdata{1};
            end
            
            numObjs = max(labdata(:));
            
            borderL = labdata;
            borderL(2:end-1,2:end-1) = 0;
            
            tstats = regionprops(borderL,'Area');
            
            if numel(tstats)<numObjs
                [tstats((numel(tstats)+1):numObjs).Area] = deal(0);
            end
            
            isEdge = cellfun(@(x)x>0, {tstats.Area}','uni',false);
            [stats(1:numObjs,1).EdgeTouch] = isEdge{:};
            
            if this.Detail>1
                [stats.EdgeAmount] = tstats.Area;
            end
            
            if ~isempty(this.Prefix)
                stats = prefixFields(stats,this.Prefix);
            end
            
            
            if nargout>1
                for ii = (nargout-1):-1:1
                    varargout{ii} = [];
                end
            end
        end
    end
end