classdef ShapeBinsAZMeasure < AZMeasure
    % Statistics reflecting the cell shape, using the histogram of the cell boundary distance transform.
    properties
        NumBins = 5;
    end
    methods
        function this = ShapeBinsAZMeasure(propPrefix,numbins)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(numbins)
                this.NumBins = numbins;
            end
        end
        
        function [stats,varargout] = measure(this,labdata,~)
            if iscell(labdata)
                labdata = labdata{1};
            end
            
            % for now, assume that the labels aren't touching each other
            D = bwdist(labdata==0);
            tstats = regionprops(labdata,D,'maxintensity');
            maxD = propimage(labdata,[tstats.MaxIntensity]',1);
            D = ceil(this.NumBins*D./maxD);
            D(D==0) = 1;
            D(D>this.NumBins) = this.NumBins;
            
            try
            countdata = accumarray([labdata(labdata>0),D(labdata>0)],ones(nnz(labdata>0),1),[max(labdata(:)),this.NumBins]);
            catch ME
                rethrow(ME)
            end
            % this probably should be normalized by the total area
            countdata = bsxfun(@rdivide,countdata,sum(countdata,2));
            
            countdata = num2cell(countdata,2);
            [stats(1:numel(countdata),1).AreaBins] = countdata{:};
            
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
