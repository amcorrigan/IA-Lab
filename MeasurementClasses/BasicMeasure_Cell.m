classdef BasicMeasure_Cell < AZMeasure
    % Basic shape measurements - area, aspect, solidity, etc
    properties
        
    end
    methods
        function this = BasicMeasure_Cell(propPrefix, outputType)
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
                lCyto = L{2};
            end
            
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            if size(L,3)==1
                % label is 2D, so need to sum-project the image data
                imdata = cellfun(@(x)sum(x,3),imdata,'uni',false);
            end

            %_______________________________________________
            %   Nuc Channel
            STATS_Nuc = regionprops(lNuc, imdata{1}, 'MeanIntensity',...
                                                     'Area', ...
                                                     'MajorAxisLength',...
                                                     'MinorAxisLength',...
                                                     'Centroid',...
                                                     'Solidity',...
                                                     'Eccentricity',...
                                                     'Perimeter'...
                                                     );
            areaNuc = [STATS_Nuc.Area];                                 
            dnaContentMean = [STATS_Nuc.MeanIntensity];
            dnaContentSum = dnaContentMean .* areaNuc;
            circularity = 4 * pi * areaNuc ./ (eps + [STATS_Nuc.Perimeter].^2);
            lengthRatio = [STATS_Nuc.MinorAxisLength] ./ (eps + [STATS_Nuc.MajorAxisLength]);
            solidity = [STATS_Nuc.Solidity];
            eccentricity = [STATS_Nuc.Eccentricity];
            
            centroidX = zeros(1, length(STATS_Nuc));
            centroidY = centroidX;
            
            for i = 1:length(STATS_Nuc)
                centroidX(i) = STATS_Nuc(i).Centroid(1);
                centroidY(i) = STATS_Nuc(i).Centroid(1);
            end
            
            %_______________________________________________
            %   Cyto Channel
            STATS_Cyto = regionprops(lCyto, imdata{2}, 'MeanIntensity',...
                                                       'Area', ...
                                                       'MaxIntensity'...
                                                       );
            
            areaCyto = [STATS_Cyto.Area];                                 
            markerMean = [STATS_Cyto.MeanIntensity];
            markerSum = markerMean .* areaCyto;
%             markerMax = [STATS_Cyto.MaxIntensity];  %-- matlab bug, does not count nan!!!
            
            %-- in case Cyto(end few) does not exist (smaller than nuc)
            if length(STATS_Nuc) > length(STATS_Cyto)
                lenDiff = length(STATS_Nuc) - length(STATS_Cyto);
                
                pad = zeros(1, lenDiff);
                
                areaCyto = [areaCyto, pad];
                markerMean = [markerMean, pad];
                markerSum = [markerSum, pad];
%                 markerMax = [markerMax, pad];
            end
            
            ncRatioArea = areaCyto./(eps + areaNuc);
            ncRatioMeanInt = markerMean./(eps + dnaContentMean);
            ncRatioSumInt = markerSum./(eps + dnaContentSum);
            
            if strcmp(this.OutputType, 'SingleCell') == true
                for i = 1:length(areaNuc)
                    o_stats(i).areaNuc = areaNuc(i);
                    o_stats(i).dnaContentMean = dnaContentMean(i);
                    o_stats(i).dnaContentSum = dnaContentSum(i);
                    o_stats(i).circularity = circularity(i);
                    o_stats(i).lengthRatio = lengthRatio(i);
                    o_stats(i).solidity = solidity(i);
                    o_stats(i).eccentricity = eccentricity(i);
                    o_stats(i).centroidX = centroidX(i);
                    o_stats(i).centroidY = centroidY(i);
                    o_stats(i).areaCyto = areaCyto(i);
                    o_stats(i).markerMean = markerMean(i);
                    o_stats(i).markerSum = markerSum(i);
%                     o_stats(i).markerMax = markerMax(i);
                    o_stats(i).ncRatioArea = ncRatioArea(i);
                    o_stats(i).ncRatioMeanInt = ncRatioMeanInt(i);
                    o_stats(i).ncRatioSumInt = ncRatioSumInt(i);
                end;
            else
                o_stats(1).areaNuc = nanmean(areaNuc);
                o_stats(1).dnaContentMean = nanmean(dnaContentMean);
                o_stats(1).dnaContentSum = nanmean(dnaContentSum);
                o_stats(1).circularity = nanmean(circularity);
                o_stats(1).lengthRatio = nanmean(lengthRatio);
                o_stats(1).solidity = nanmean(solidity);
                o_stats(1).eccentricity = nanmean(eccentricity);
                o_stats(1).areaCyto = nanmean(areaCyto);
                o_stats(1).markerMean = nanmean(markerMean);
                o_stats(1).markerSum = nanmean(markerSum);
%                 o_stats(1).markerMax = nanmean(markerMax);
                o_stats(1).ncRatioArea = nanmean(ncRatioArea);
                o_stats(1).ncRatioMeanInt = nanmean(ncRatioMeanInt);
                o_stats(1).ncRatioSumInt = nanmean(ncRatioSumInt);
            end;
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