classdef MeasureExtractCellomics < AZMeasure
    % Extract Cellomics segmentation results from the object files
    properties
        
    end
    methods
        function this = MeasureExtractCellomics(propPrefix, outputType)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
            
            if nargin == 2
                this.OutputType = outputType;
            end;
        end
        
        
        function [o_stats,varargout] = measure(this,L,imdata)
            
            %_______________________________________________
            %
            if iscell(L)
                lNuc = L{1};
            end
            
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            if size(L,3)==1
                % label is 2D, so need to sum-project the image data
                imdata = cellfun(@(x)sum(x,3),imdata,'uni',false);
            end

            o_stats(1).areaNuc = 0;

            
            %_______________________________________________
            %
            if ~isempty(this.Prefix)
                o_stats = prefixFields(o_stats,this.Prefix);
            end
            
            if nargout>1
                for ii = (nargout-1):-1:1
                    varargout{ii} = [];
                end
            end
        end
    end
end