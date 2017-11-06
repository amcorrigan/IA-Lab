classdef SubcellIntensityAZMeasure < AZMeasure
    % Intensity by subdividing the cell into regions based on the distance from the cell edge.
    properties
        NumBins = 3;
        UseConvexImage = true;
    end
    methods
        function this = SubcellIntensityAZMeasure(propPrefix,numbins)
            % use explicit inputs rather than varargin to make calling
            % syntax clearer
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            
            this = this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(numbins)
                this.NumBins = numbins;
            end
        end
        
        function [stats,varargout] = measure(this,L,imdata)
            % should only be one label, calculate the intensity
            % distributions for all supplied image channels
            if iscell(L)
                L = L{1};
            end
            if size(L,3)>1
                L = max(L,[],3);
            end
            
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            lstats = regionprops(L,'FilledImage','BoundingBox','ConvexImage');
            
            
            sumim = cellfun(@(x)sum(x,3),imdata,'uni',false);
            
            
            % if the convex image is going to be used, then the
            % measurements MUST be done one label at at time, because the
            % convex hull could overlap each other.
            
            qvals = (1:(this.NumBins-1))'/this.NumBins;
            
            for ii = max(L(:)):-1:1
                
                if this.UseConvexImage
                    maskim = lstats(ii).ConvexImage;
                else
                    maskim = lstats(ii).FilledImage;
                end
                
                D = bwdist(~padarray(maskim,[1,1],false,'both'));
                D = D(2:end-1,2:end-1);
                
                % the D values need converting into quantiles
                dvals = D(maskim);
                dvals = dvals(isfinite(dvals));
                
                [dhist,x] = hist(dvals,200);
                
                x(dhist==0) = [];
                dhist(dhist==0) = [];
                cumud = cumsum(dhist);
                cumud = cumud/cumud(end);
                dq = interp1(cumud,x,qvals);
                
                qim = imquantize(D,dq);
                
                for jj = 1:numel(imdata)
                    stats(ii).(sprintf('QuantileMeanCh%d',jj)) = accumarray(...
                        qim(maskim),sumim{jj}(maskim),[this.NumBins,1],@mean)';
                    stats(ii).(sprintf('QuantileStdevCh%d',jj)) = accumarray(...
                        qim(maskim),sumim{jj}(maskim),[this.NumBins,1],@std)';
                end
                
            end
            
            if ~isempty(this.Prefix)
                stats = prefixFields(stats,this.Prefix);
            end
        end
    end
end
