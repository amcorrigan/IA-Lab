classdef ShapeStatsAZMeasure < AZMeasure
    % Measure shape properties for the segmented regions
    %
    % Start off with the usual suspects, volume, aspect ratio, convex ratio
    % THIS ISN'T FULLY COMPLETE YET, JUST WORKING AS A CONCEPT
    
    properties
        
    end
    methods
        function this = ShapeStatsAZMeasure(propPrefix)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
        end
        
        function [stats,varargout] = measure(this,L,~)
            % image data not required
            
            if iscell(L)
                L = L{1};
            end
            
            substats = regionprops(L,'area','MajorAxisLength','MinorAxisLength','Centroid','Perimeter');
            
            centxy = cell2mat({substats.Centroid}')';
            centx = num2cell(centxy(1,:));
            centy = num2cell(centxy(2,:));
            
            try
            stats = struct([this.Prefix,'PixelArea'],{substats.Area},...
                [this.Prefix,'AspectRatio'],num2cell([substats.MajorAxisLength]./[substats.MinorAxisLength]),...
                [this.Prefix,'CentroidX'],centx,[this.Prefix,'CentroidY'],centy);
            catch ME
                rethrow(ME)
            end
            
            if nargout>1
                for ii = 1:(nargout-1)
                    varargout{ii} = [];
                end
            end
        end
    end
end