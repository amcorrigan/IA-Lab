classdef NucStats3DAZMeasure < AZMeasure
    % Measure Nuclear properties from 3D labels
    % To begin with, this is very similar to the ShapeStatsAZMeasure class,
    % but includes nuclei-specific measures, such as the total DNA content
    % as measured by the summed intensity
    %
    % Also, a good measure of nuclear texture and morphology should be
    % added when required.
    properties
        
    end
    methods
        function this = NucStats3DAZMeasure(propPrefix)
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
            
            if max(L(:))>0
% %             if size(L,3)==1
% %                 % label is 2D, so need to sum-project the image data
% %                 imdata = cellfun(@(x)sum(x,3),imdata,'uni',false);
% %             end
            
            substats = regionprops(L,'area','Centroid');
            
            centxy = cell2mat({substats.Centroid}')';
            centx = num2cell(centxy(1,:));
            centy = num2cell(centxy(2,:));
            centz = num2cell(centxy(3,:));
            
            try
            stats = struct('Volume',{substats.Area},'CentroidX',centx,'CentroidY',centy,...
                'CentroidZ',centz);
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
            else
                fields = {'PixelArea','CentroidX','CentroidY'};
                for ii = 1:numel(imdata)
                    fields = [fields,{sprintf('SumIntensityCh%d',ii)}];
                end
                if ~isempty(this.Prefix)
                    for ii = 1:numel(fields)
                        fields{ii} = sprintf('%s%s',this.Prefix,fields{ii});
                    end
                end
                
                args = [fields;repmat({{}},[1,numel(fields)])];
                stats = struct(args{:});
            end
            
            if nargout>1
                for ii = (nargout-1):-1:1
                    varargout{ii} = [];
                end
            end
        end
    end
end