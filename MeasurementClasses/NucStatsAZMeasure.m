classdef NucStatsAZMeasure < AZMeasure
    % Measure Nuclear properties, including total DNA content for cell-cycle.
    % To begin with, this is very similar to the ShapeStatsAZMeasure class,
    % but includes nuclei-specific measures, such as the total DNA content
    % as measured by the summed intensity
    %
    % Also, a good measure of nuclear texture and morphology should be
    % added when required.
    properties
        
    end
    methods
        function this = NucStatsAZMeasure(propPrefix)
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
            
            if size(L,3)==1
                % label is 2D, so need to sum-project the image data
                imdata = cellfun(@(x)sum(x,3),imdata,'uni',false);
            end
            
            substats = regionprops(L,'area','MajorAxisLength','MinorAxisLength','Centroid','Perimeter');
            
            centxy = cell2mat({substats.Centroid}')';
            centx = num2cell(centxy(1,:));
            centy = num2cell(centxy(2,:));
            
            try
            stats = struct('PixelArea',{substats.Area},...
                'AspectRatio',num2cell([substats.MajorAxisLength]./[substats.MinorAxisLength]),...
                'CentroidX',centx,'CentroidY',centy,'PixelPerimeter',{substats.Perimeter});
            catch ME
                rethrow(ME)
            end
            
            try
            for ii = 1:numel(imdata)
                % rather than always using regionprops, try direct
                % calculation
                data = num2cell(accumarray(L(L>0),imdata{ii}(L>0),[max(L(:)),1]));
                [stats.(sprintf('SumIntensityCh%d',ii))] = data{:};
            end
            catch ME
                rethrow(ME)
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