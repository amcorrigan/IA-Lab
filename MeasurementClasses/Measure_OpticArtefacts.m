classdef Measure_OpticArtefacts < AZMeasure
    % Calculate the magnitude of optical artefacts in the image
    methods
        function this = Measure_OpticArtefacts(propPrefix, outputType)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
            
            if nargin == 2
                this.OutputType = outputType;
            end;

            this.OutputType = 'Field';
            
        end
        
        
        function [o_stats,varargout] = measure(this,L,imdata)
            
            %_______________________________________________
            %
            if iscell(L)
                lCyto = L{1};
            end
            
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            if size(L,3)==1
                % label is 2D, so need to sum-project the image data
                imdata = cellfun(@(x)sum(x,3),imdata,'uni',false);
            end
            
            imdata{2} = im2double(imdata{2})./65536;
            
            SE = strel('disk', 20);

            obr = imreconstruct(imerode(imdata{2}, SE), imdata{2});

            [~, thresh] = uh_getThresholdPossian(obr);
            
            STATS = regionprops(lCyto, imdata{2}, 'MeanIntensity', 'Area');
            
            meanInt = [STATS.MeanIntensity];
            area = [STATS.Area];
            
            o_stats(1).thresh = thresh;
            o_stats(1).meanInt = sum(meanInt.*area)./(sum(area)+eps);
            o_stats(1).area = sum(area);

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