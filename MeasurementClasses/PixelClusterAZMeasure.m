classdef PixelClusterAZMeasure < AZMeasure
    % (Deprecated) Measure the extent of clustering from the radial distribution function.
    properties
        
    end
    methods
        function this = PixelClusterAZMeasure(propPrefix)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
        end
        
        function [stats,varargout] = measure(this,L,imdata)
            
            if iscell(L)
                L = L{1};
            end
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            
            tempstats = regionprops(L,'PixelList','PixelIdxList');
            
            for ii = 1:numel(tempstats)
                dd = pdist(tempstats(ii).PixelList);
                dd = dd(:);
                dq = ceil((dd+1)/4);
                inds = dq<=20;
                dq = dq(inds);
                
                iprod = pdist(double(imdata{1}(tempstats(ii).PixelIdxList)),@(x,y)x*y);
                iprod = iprod(:);
                iprod = iprod(inds);
                
                n0 = accumarray(dq(:),ones(numel(dq),1),[20,1]);
                ip = accumarray(dq(:),iprod(:),[20,1]);
                rdf = ip./n0;
                
                stats(ii).RDF = rdf/sum(rdf(:));
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
