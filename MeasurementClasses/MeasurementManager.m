classdef MeasurementManager < handle
    % Manager for the measurements, which passing the correct channels to each measurement module and combining the outputs.
    properties
        MeasArray = {}
        InputChannels = {}
        InputLabels = {}
    end
    methods
        function this = MeasurementManager()
            
        end
        
        function addMeasurement(this,measObj,labChannel,imChannel)
            count = numel(this.MeasArray) + 1;
            
            this.MeasArray{count,1} = measObj;
            
            % check these against the numbers specified in the measurement
            % class at some point
            this.InputLabels{count,1} = labChannel;
            this.InputChannels{count,1} = imChannel;
            
            
            
        end
        
        function statsVector = measure(this,labelData,imData,varargin)
            % the varargin can be fieldname-value pairs that will be added
            % to the stats structure - eg well ID or platename or similar
            % it's debatable whether this is done here or outside
            % or whether a separate function should do this offline
            
            if isa(imData,'cImageInterface')
                % we've supplied an image object rather than a cell of
                % arrays
                imData = imData.rawdata();
            end
            
            cellStats = [];
            fieldStats = [];
            
            % want to update this so that infinity in the inputchannels
            % denotes that all channels should be used (without having to
            % know in advance how many channels there are)
            for ii = 1:numel(this.MeasArray)
                % this assumes that all of the measures are single cell,
                % and so will all be the same size
                L = labelData(this.InputLabels{ii});
                im = imData(this.InputChannels{ii});
                stats0 = this.MeasArray{ii}.measure(L,im);
                
                if strcmpi(this.MeasArray{ii}.OutputType,'SingleCell')
                    if isempty(cellStats)
                        cellStats = stats0;
                    else
                        try
                        cellStats = mergefields(cellStats,stats0);
                        catch ME
                            rethrow(ME)
                        end
                    end
                else
                    if isempty(fieldStats)
                        fieldStats = stats0;
                    else
                        fieldStats = mergefields(fieldStats,stats0);
                    end
                end
            end
            % also want to add a cell index to the stats structure for
            % single cell measures (but not for field averaged measures)
            
            % Seems like a good idea to do that here rather than waiting
            % till we try to read it in
            
            if numel(varargin)>0
                if numel(varargin)==1 && isstruct(varargin{1})
                    scalarstruct = varargin{1};
                else
                    scalarstruct = struct(varargin{:});
                end
                fixstruct = repmat(scalarstruct,size(cellStats));
                cellStats = mergefields(fixstruct,cellStats);
                
                fixstruct = repmat(scalarstruct,size(fieldStats));
                fieldStats = mergefields(fixstruct,fieldStats);
                
            end
            
            if ~isempty(cellStats)
                temp = num2cell(1:numel(cellStats));
                [cellStats.ObjectIndex] = temp{:}; % would this be better referred to as object index?
            end
            
            statsVector = {cellStats;fieldStats};
        end
        
        function setPixelSize(this,pixsize)
            % add pixel size information to the measurement classes that
            % require it.
            % This is because sometimes we might be creating the
            % measurements and workflow before we know what parser is going
            % to be used
            
            for ii = 1:numel(this.MeasArray)
                if isa(this.MeasArray{ii},'AZMeasurePixels')
                    this.MeasArray{ii}.setPixelSize(pixsize);
                end
            end
            
        end
    end
end