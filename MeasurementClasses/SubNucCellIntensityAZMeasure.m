classdef SubNucCellIntensityAZMeasure < AZMeasure
% Intensity by subdividing the cell into regions based on the distance from the cell and nucleus edges.
    properties
        NumBins = 3;
        UseConvexImage = true;
    end
    methods
        function this = SubNucCellIntensityAZMeasure(propPrefix,numbins)
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
            if ~iscell(L)
                error('Need two labels - nuclei and cell')
            end
            L = cellfun(@(x)max(x,[],3), L,'uni',false);
            
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
%             nucstats = regionprops(L{1},'FilledImage','BoundingBox','ConvexImage');
            cellstats = regionprops(L{2},'FilledImage','BoundingBox','ConvexImage');
            
            imdata = cellfun(@(x)sum(x,3),imdata,'uni',false);
            
            
            % if the convex image is going to be used, then the
            % measurements MUST be done one label at at time, because the
            % convex hull could overlap each other.
            
            qvals = (1:(this.NumBins-1))'/this.NumBins;
            
            for ii = max(L{1}(:)):-1:1
                
                if this.UseConvexImage
                    dmask = cellstats(ii).ConvexImage;
                else
                    dmask = cellstats(ii).FilledImage;
                end
                maskim = cellstats(ii).FilledImage;
                
                xrange = [cellstats(ii).BoundingBox(2)+0.5, cellstats(ii).BoundingBox(2)+cellstats(ii).BoundingBox(4)-0.5];
                yrange = [cellstats(ii).BoundingBox(1)+0.5, cellstats(ii).BoundingBox(1)+cellstats(ii).BoundingBox(3)-0.5];
                
                nucmask = L{1}(xrange(1):xrange(2),yrange(1):yrange(2))==ii;
                
                D = bwdist(~padarray(dmask,[1,1],false,'both'));
                D = D(2:end-1,2:end-1);
                
                outernucD = bwdist(nucmask);
                innernucD = bwdist(~padarray(nucmask,[1,1],false,'both'));
                innernucD = innernucD(2:end-1,2:end-1);
                % the D values need converting into quantiles
                celldvals = D(maskim & ~nucmask);
                outnucdvals = outernucD(maskim & ~nucmask);
                dvals = celldvals./(celldvals + outnucdvals);
                % this is dvals only for the cytoplasm
                
                dvals = dvals(isfinite(dvals));
                
                [dhist,x] = hist(dvals,200);
                
                x(dhist==0) = [];
                dhist(dhist==0) = [];
                cumud = cumsum(dhist);
                if numel(cumud)<2
                    for jj = 1:numel(imdata)
                        stats(ii).(sprintf('QuantileMeanCh%d',jj)) = NaN*ones([2*this.NumBins,1]);
                        stats(ii).(sprintf('QuantileStdevCh%d',jj)) = NaN*ones([2*this.NumBins,1]);
                    end
                    continue;
                end
                cumud = cumud/cumud(end);
                
                try
                dq = interp1(cumud,x,qvals,'linear','extrap');
                dq = max(0,dq);
                
                deltad = [diff(dq);1];
                inds = find(deltad==0);
                for kk = numel(inds):-1:1
                    dq(inds(kk)) = dq(inds(kk)+1) - 0.001;
                end
                
                cqvals = imquantize(dvals,dq);
                catch ME
                    rethrow(ME)
                end
                
                % overlay the nuclei quantile over the top
                
                innucdvals = innernucD(nucmask);
                % this is the distance for inside the nuclei
                
                innucdvals = innucdvals(isfinite(innucdvals));
                [dhist,x] = hist(innucdvals,200);
                
                x(dhist==0) = [];
                dhist(dhist==0) = [];
                cumud = cumsum(dhist);
                if numel(cumud)<2
                    for jj = 1:numel(imdata)
                        stats(ii).(sprintf('QuantileMeanCh%d',jj)) = NaN*ones([2*this.NumBins,1]);
                        stats(ii).(sprintf('QuantileStdevCh%d',jj)) = NaN*ones([2*this.NumBins,1]);
                    end
                    continue;
                end
                
                cumud = cumud/cumud(end);
                dq = interp1(cumud,x,qvals,'linear','extrap');
                dq = max(0,dq);
                
                deltad = [diff(dq);1];
                inds = find(deltad==0);
                for kk = numel(inds):-1:1
                    dq(inds(kk)) = dq(inds(kk)+1) - 0.001;
                end
                
                try
                nqvals = imquantize(innucdvals,dq);
                catch ME
                    rethrow(ME)
                end
                
                qim = zeros(size(maskim));
                qim(maskim & ~nucmask) = cqvals;
                qim(nucmask) = this.NumBins + nqvals;
                
                
                for jj = 1:numel(imdata)
                    stats(ii).(sprintf('QuantileMeanCh%d',jj)) = accumarray(...
                        qim(maskim),imdata{jj}(maskim),[2*this.NumBins,1],@mean)';
                    stats(ii).(sprintf('QuantileStdevCh%d',jj)) = accumarray(...
                        qim(maskim),imdata{jj}(maskim),[2*this.NumBins,1],@std)';
                end
                
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
