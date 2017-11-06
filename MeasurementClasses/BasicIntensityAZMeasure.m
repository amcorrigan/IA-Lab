classdef BasicIntensityAZMeasure < AZMeasure
    % Measure the mean intensity, max and min, and also area so that total intensity can be calculated.
    properties
        DetailLevel = 0;
        
        BgRemovalFcn = [];
    end
    methods
        function this = BasicIntensityAZMeasure(propPrefix,detail,outputType)
            if nargin<2 || isempty(detail)
                detail = 0;
            end
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
            
            
            this.DetailLevel = detail;
            
            if nargin>2 && ~isempty(outputType)
                this.OutputType = outputType; % defaults to singlecell, but for masks we might want a field-level measurement
            end
        end
        
        function [stats,varargout] = measure(this,L,imdata)
            if ~iscell(imdata)
                imdata = {imdata};
            end
            if iscell(L)
                L = L{1};
            end
            
            if size(L,3)>1
                sizefield = 'Volume';
            else
                sizefield = 'Area';
            end
            
            if strcmpi(this.OutputType,'Field')
                % want to make sure that the binary mask isn't interpreted
                % as distinct regions
                L = double(L>0);
            end
            
            if this.DetailLevel>=1
                tempstats = regionprops(L,sizefield);
                areaoutputname = [this.Prefix,sizefield];
                [stats(1:numel(tempstats),1).(areaoutputname)] = tempstats.Area;
            end
            
            for ii = 1:numel(imdata)
                if isempty(this.BgRemovalFcn)
                    currimdata = imdata{ii};
                else
                    currimdata = this.BgRemovalFcn(imdata{ii});
                end
                
                tempstats = regionprops(L,currimdata,'MeanIntensity','MaxIntensity','MinIntensity');
                
                outputname = [this.Prefix,'MeanIntensityCh',num2str(ii)];
                [stats(1:numel(tempstats),1).(outputname)] = tempstats.MeanIntensity;
                
                if this.DetailLevel>=2
                    outputname = [this.Prefix,'MaxIntensityCh',num2str(ii)];
                    [stats(1:numel(tempstats),1).(outputname)] = tempstats.MaxIntensity;

                    outputname = [this.Prefix,'MinIntensityCh',num2str(ii)];
                    [stats(1:numel(tempstats),1).(outputname)] = tempstats.MinIntensity;
                end
                
                if this.DetailLevel>=1
                    % also want to calculate the total intensity
                    % do it here, rather than having to mess around outside
                    totalint = num2cell([tempstats.MeanIntensity]'.*[stats.(areaoutputname)]');

                    outputname = [this.Prefix,'TotalIntensityCh',num2str(ii)];
                    [stats(1:numel(tempstats),1).(outputname)] = totalint{:};
                end
            end
        end
    end
end
