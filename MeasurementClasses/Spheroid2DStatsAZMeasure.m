classdef Spheroid2DStatsAZMeasure < AZMeasurePixels
    % Measure shape properties for the segmented spheroid (note that this expects one spheroid per image).
    %
    % Start off with the usual suspects, volume, aspect ratio, convex ratio
    % THIS ISN'T FULLY COMPLETE YET, JUST WORKING AS A CONCEPT
    
    properties
        
    end
    methods
        function this = Spheroid2DStatsAZMeasure(propPrefix,pixsize)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this@AZMeasurePixels(propPrefix,pixsize);
        end
        
        function o_stats = measure(this,L,imData)
            
            if iscell(L)
                L = L{1};
            end
            
            if iscell(imData)
                imData = imData{1};
            end;
            
            STATS = regionprops(L, imData, 'Area', ...
                                           'Perimeter', ...
                                           'EquivDiameter',...
                                           'Solidity',...
                                           'Extent', ...
                                           'Eccentricity',...
                                           'MajorAxisLength',...
                                           'MinorAxisLength',...
                                           'MeanIntensity');
            if isempty(STATS)
                o_stats.Flag = false;
                o_stats.Area = nan;
                o_stats.Perimeter = nan;
                o_stats.EquivDiameter = nan;
                o_stats.Solidity = nan;
                o_stats.Extent = nan;
                o_stats.Eccentricity = nan;
                o_stats.Roundness = nan;
                o_stats.AspectRatio = nan;
                o_stats.ShapeFactor = nan;
                o_stats.FormFactor = nan;
                o_stats.MeanIntensity = nan;
                
            else
                o_stats.Flag = true;
                                 
                                       
                o_stats.Area = STATS(1).Area;
                o_stats.Perimeter = STATS(1).Perimeter;
                o_stats.EquivDiameter = STATS(1).EquivDiameter;
                o_stats.Solidity = STATS(1).Solidity;
                o_stats.Extent = STATS(1).Extent;
                o_stats.Eccentricity = STATS(1).Eccentricity;

                o_stats.Roundness = 4 * STATS(1).Area / (STATS(1).MajorAxisLength * STATS(1).MajorAxisLength * pi + eps);       %-- Roundness
                o_stats.AspectRatio = STATS(1).MinorAxisLength / (STATS(1).MajorAxisLength + eps);        %-- Aspect Ratio
                o_stats.ShapeFactor = STATS(1).Perimeter / (sqrt(STATS(1).Area) + eps);                  %-- Shape factor
                o_stats.FormFactor = 4 * pi * STATS(1).Area / (STATS(1).Perimeter * STATS(1).Perimeter + eps);     %-- Form factor

                o_stats.MeanIntensity = STATS(1).MeanIntensity; 
            end
            if ~isempty(this.Prefix)
                o_stats = prefixFields(o_stats,this.Prefix);
            end
            
% %             if nargout>1
% %                 for ii = 1:(nargout-1)
% %                     varargout{ii} = [];
% %                 end
% %             end
        end
    end
end