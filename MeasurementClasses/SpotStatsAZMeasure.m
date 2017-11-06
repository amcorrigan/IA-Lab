classdef SpotStatsAZMeasure < AZMeasure
    % Statistics of spots (label 2) in each object (label 1) (number, location, intensity).
    properties
        NumBins = 3;
        DetailLevel = 1; % by default, only the spreadsheet exportable properties
        % 1 = 
        % 2 = including intensities of all the spots
        % 3 = including locations of all the spots (not finished yet)
    end
    methods
        function this = SpotStatsAZMeasure(propPrefix,numbins,detail)
            % use explicit inputs rather than varargin to make calling
            % syntax clearer
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            
            this = this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(numbins)
                this.NumBins = numbins;
            end
            if nargin>2 && ~isempty(detail)
                this.DetailLevel = detail;
            end
            
            this.NumInputLabels = 2;
            
        end
        
        function [stats,varargout] = measure(this,L,imdata)
            
            % L is cell array
            % first element = cell label
            % second element = spot label
            
            % need to put each spot into the correct cell
            % so this class supercedes the simpler spot count one (don't
            % run both!)
            
            % interpolate the nearest object of the spot location
            if all(size(L{2}(:,:,1))==size(L{1}(:,:,1)))
                sxyz = findn(L{2});
            else
                sxyz = L{2};
            end
            
            % want to make sure that this doesn't crash when there are no
            % spots!
            
            if ~isempty(sxyz)
                % this could be done using linear indexing rather than
                % interpolation
                if size(L{1},3)==1 || size(sxyz,2)<3
                    cellidx = interp2(L{1},sxyz(:,2),sxyz(:,1),'nearest');
                else
                    cellidx = interp3(L{1},sxyz(:,2),sxyz(:,1),sxyz(:,3),'nearest');
                end
                spotcount = accumarray(cellidx(cellidx>0),ones(nnz(cellidx>0),1),[max(L{1}(:)),1]);
            else
                cellidx = [];
                spotcount = zeros(max(L{1}(:)),1);
            end
            
            fname = [this.Prefix,'SpotCount'];
            stats = struct(fname,num2cell(spotcount));
            
            zeroCount = nnz(cellidx==0);
            
            lstats = regionprops(L{1},'FilledImage','BoundingBox','ConvexImage');
            
            for ii = 1:numel(lstats)
                D = bwdist(~lstats(ii).FilledImage);
                % could repeat this for the convex image if the shape is
                % very complex
                
                try
                dvals = D(lstats(ii).FilledImage);
                dvals = dvals(isfinite(dvals));
                
                if ~isempty(dvals) && nnz(cellidx==ii)>0
                    nn = cumsum(inthist(dvals,0));
                    nn = nn/nn(end);
                    
                    if numel(nn)>1
                    
                        if size(sxyz,2)>2
                            offvals = [lstats(ii).BoundingBox([2,1])-0.5,0];
                        else
                            offvals = lstats(ii).BoundingBox([2,1]);
                        end
                        oxyz = bsxfun(@minus,sxyz(cellidx==ii,:),offvals);

                        rawD = interp2(D,oxyz(:,2),oxyz(:,1));

                        dp = NaN*ones(size(rawD));
                        dp(~isnan(rawD)) = interp1((1:numel(nn))',nn,rawD(~isnan(rawD)));
                    else
                        dp = NaN;
                    end
                    % this is a percentile for every spot in the cell
                    % to begin with, store all the percentiles, and also binned
                    % into 0.1 width bins.
                    qp = max(1,min(this.NumBins,ceil(this.NumBins*dp)));
                    spotdist = accumarray(qp,ones(size(qp)),[this.NumBins,1]);
                else
                    dp = NaN*ones(nnz(cellidx==ii),1);
                    spotdist = zeros(this.NumBins,1);
                end
                
                catch ME
                    rethrow(ME)
                end
                
                stats(ii).([this.Prefix, 'SpotDist']) = spotdist;
                stats(ii).([this.Prefix, 'SpotPercentile']) = dp;
                
                
            end

            if this.DetailLevel>1 && nargin>2 && ~isempty(imdata)
                % also want to get the peak intensity of each spot
                % as it's only a relative measure, a diamond structure
                % element can be used.
                
                % let's hope that the right channel has been supplied - is
                % there a way to ensure this?
                
                if iscell(imdata)
                    imdata = imdata{1};
                end
                
                spotL = zeros(size(imdata));
                linind = amcSub2Ind(size(imdata),round(sxyz));
                
                linind(linind<1 | linind>numel(imdata)) = [];
                
                spotL(linind) = (1:size(sxyz,1))';
                
                spotL = imdilate(spotL,diamondElement);
                
                %just use regionprops for this, though it might be quicker
                %to use accumarray if the dilation can be done directly on
                %the coordinates
                istats = regionprops(spotL,imdata,'MeanIntensity','MaxIntensity');
                
                % want to assign this to individual cells, rather than on a
                % per-spot basis
                
                [stats.([this.Prefix, 'MaxSpotInts'])] = istats.MaxIntensity;
                [stats.([this.Prefix, 'MeanSpotInts'])] = istats.MeanIntensity;
                
            end

            if nargout>1
                varargout{1} = zeroCount;
            end
            
        end
    end
end
