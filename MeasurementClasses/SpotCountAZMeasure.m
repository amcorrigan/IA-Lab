classdef SpotCountAZMeasure < AZMeasure
    % count how many spots (label 2) are in each object (label 1)
    properties
        
    end
    methods
        function this = SpotCountAZMeasure(propPrefix)
            % use explicit inputs rather than varargin to make calling
            % syntax clearer
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
        end
        
        function [stats,varargout] = measure(this,L,~)
            % imdata not required for this one
            
            % interpolate the nearest object of the spot location
            if all(size(L{2}(:,:,1))==size(L{1}(:,:,1)))
                sxyz = findn(L{2});
            else
                sxyz = L{2};
            end
            
            % this could be done using linear indexing rather than
            % interpolation
            if size(L{1},3)==1 || size(sxyz,2)<3
                cellidx = interp2(L{1},sxyz(:,2),sxyz(:,1),'nearest');
            else
                cellidx = interp3(L{1},sxyz(:,2),sxyz(:,1),sxyz(:,3),'nearest');
            end
            spotcount = accumarray(cellidx(cellidx>0),ones(nnz(cellidx>0),1),[max(L{1}(:)),1]);
            
            fname = [this.Prefix,'SpotCount'];
            stats = struct(fname,num2cell(spotcount));
            
            zeroCount = nnz(cellidx==0);
            
            if nargout>1
                varargout{1} = zeroCount;
            end
            
        end
    end
end
