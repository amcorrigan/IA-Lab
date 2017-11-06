classdef MicroNucleiAZMeasure < AZMeasure
    % Calculate statistics of micro-nuclei - area, intensity and distance from the nucleus.
    properties
        
    end
    methods
        function this = MicroNucleiAZMeasure(propPrefix)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            
            this@AZMeasure(propPrefix);
        end
        function [stats,varargout] = measure(this,L,imdata)
            
            % The order of the label channels should be nuclei, cell,
            % micronuclei?
            
            % Measurements required:
            % - indices of micronuclei per nucleus (and therefore number of
            %   micronuclei in each cell)
            % - sum intensity of the micronuclei
            % - total area of micronuclei
            % - some measure of location within the cell
            
            % The comparison with the nuclei intensity should be left to
            % the data analysis stage
            
            if ~iscell(L)
                error('Need 3 labels to run this at the moment')
            end
            if iscell(imdata)
                imdata = imdata{1};
            end
            
            microstats = regionprops(L{3},L{2},'MaxIntensity');
            
            cytolabels = [microstats.MaxIntensity]';
            cytolabels(cytolabels==0) = [];
            
            microInds = arrayfun(@(x)find(cytolabels==x),(1:max(L{2}(:)))','uni',false);
            [stats(1:numel(microInds),1).MicroNucIndices] = microInds{:};
            
            tempnuc = cellfun(@numel,microInds,'uni',false);
            [stats.MicroNucNumber] = tempnuc{:};
            
            cellMicroL = L{2};
            cellMicroL(L{3}==0) = 0;
            % this is the micronuclei pixels, assigned to the cell label
            
            cellstats = regionprops(cellMicroL,imdata,'Area','MeanIntensity');
            area = {cellstats.Area}';
            meanint = {cellstats.MeanIntensity}';
            inds = cellfun(@isnan,meanint);
            meanint(inds) = {0};
            
            area((numel(area)+1):numel(stats)) = {0};
            meanint((numel(meanint)+1):numel(stats)) = {0};
            
            sumInt = cellfun(@(x,y)x*y,area,meanint,'uni',false);
            [stats.MicroNucArea] = area{:};
            [stats.MicroNucSumIntensity] = sumInt{:};
            
            
            % if we also want to get the distance from the nucleus, need to
            % calculate the distance transform, limited to the nucleus
            % within each cell.  That might not be so straightforward -
            % have to cut out the filled image, get the nuclei image from
            % the bounding box, calculate the distance transform, and put
            % the distance image back in using the bounding box
            maskprops = regionprops(L{2},'Image','PixelIdxList');
            nucbw = L{1}>0;
            microbw = L{3}>0;
            
            for ii = 1:numel(maskprops)
                tempnuc = false(size(maskprops(ii).Image));
                tempmu = false(size(maskprops(ii).Image));
                
                tempnuc(maskprops(ii).Image) = nucbw(maskprops(ii).PixelIdxList);
                tempmu(maskprops(ii).Image) = microbw(maskprops(ii).PixelIdxList);
                
                D = bwdist(padarray(tempnuc,[1,1],0,'both'));
                D = D(2:end-1,2:end-1);
                
                stats(ii).MicroNucMeanNucDist = mean(D(tempmu));
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
