classdef ExportManager < handle
    % Manage the export of data to file or QC image 
    % 
    % this is the simplest of the managers, we just have to filter the
    % measurements and then export to the chosen format(s)
    % Need individual filters for each export format, as they might not be
    % the same
    
    properties
        ExportArray = {};
        NameFunc = {};
        StatsType = {}; % denotes whether to export single cell, field or both
        
        OutputFolder = [];
        
%         OutputFolderStruct
    end
    methods
        function this = ExportManager(outputfolder)
            
            if nargin>0 && ~isempty(outputfolder)
                this.setOutputFolder(outputfolder);
            end
        end
        
        function addExporter(this,expObj,nameFunc,statsType)
            this.ExportArray = [this.ExportArray;{expObj}];
            this.NameFunc = [this.NameFunc;{nameFunc}];
            
            
            if nargin<4 || isempty(statsType)
                statsType = 'SingleCell';
            end
            this.StatsType = [this.StatsType;statsType];
        end
        
        function setOutputFolder(this,outputfolder)
            this.OutputFolder = outputfolder;
        end
        function browseOutputFolder(this)
            temp = uigetdir();
            if isnumeric(temp) && temp==0
                temp = [];
            end
            this.setOutputFolder(temp);
        end
        
        function export(this,stats,labdata,imdata,iminfo)
            % we want to use the iminfo to determine which file the output
            % should be written to
            % Need some way of defining the output file names in a batch
            % fashion.
            
            % do the QC image export first
            count = 0;
            headernames = {};
            for ii = 1:numel(this.ExportArray)
                
                if strcmpi(this.ExportArray{ii}.ExportType,'image')
                    count = count + 1;
                    headernames{1,count} = sprintf('QCPath%d',count);
                    filenames{1,count} = syspath(this.QCExport(ii,labdata,imdata,iminfo));
                end
            end
            
            if ~isempty(headernames)
                % to begin with, add QC filenames by default
                % add the filenames to every element of the stats structure
                structinput = [headernames;filenames];
                structinput = structinput(:); % not sure this is strictly necessary

                newstats = struct(structinput{:});
            else
                newstats = [];
            end
            
            if iscell(stats)
                % shall we merge the struct into both?
                
                % this is cellfunable
                stats{1} = mergefields(repmat(newstats,size(stats{1})),stats{1});
                stats{2} = mergefields(repmat(newstats,size(stats{2})),stats{2});
            else
                stats = mergefields(repmat(newstats,size(stats)),stats);
            end
            
            
            for ii = 1:numel(this.ExportArray)
                if strcmpi(this.ExportArray{ii}.ExportType,'table')
                    if iscell(stats)
                        % decide which stats need to be passed
                        if strcmpi(this.StatsType{ii},'Field')
                            usestats = stats{2};
                        elseif strcmpi(this.StatsType{ii},'Both')
                            usestats = stats;
                        else
                            usestats = stats{1};
                        end
                    else
                        usestats = stats;
                    end
                    
                    this.tableExport(ii,usestats,iminfo);
                elseif strcmpi(this.ExportArray{ii}.ExportType,'other')
                    this.GeneralExport(ii,imdata,labdata,stats,iminfo);
                elseif ~strcmpi(this.ExportArray{ii}.ExportType,'image')
                    this.QCExport(ii,labdata,imdata,iminfo);
                end
            end
        end
        
        function tableExport(this,ind,stats,iminfo)
            outfile = fullfile(this.OutputFolder,...
                this.NameFunc{ind}(iminfo));
            
            
            this.ExportArray{ind}.export(stats,true,outfile);
            
        end
        
        function outfile = QCExport(this,ind,labdata,imdata,iminfo)
            % export the segmentation result as a QC image
            outfile = fullfile(this.OutputFolder,...
                this.NameFunc{ind}(iminfo));
            
            % WHERE SHOULD THE COLOUR CHANNEL SELECTION/MERGING TAKE PLACE?
            % PRESUMABLY INSIDE THE CLASS IS BEST?
            this.ExportArray{ind}.export(labdata,imdata,outfile);
        end
        
        function outfile = GeneralExport(this,ind,imdata,labdata,stats,iminfo)
            % export the segmentation result as a QC image
            outfile = fullfile(this.OutputFolder,...
                this.NameFunc{ind}(iminfo));
            
            this.ExportArray{ind}.export(imdata,labdata,stats,outfile);
        end
        
        function outfile = getOutputFile(this,ind,iminfo)
            if ischar(ind)
                if strcmpi(ind,'label')
                    % find the label mat export index
                    ind = find(cellfun(@(x)isa(x,'MatLabelAZExport'),this.ExportArray));
                else
                    % find the stats mat export index
                    ind = find(cellfun(@(x)isa(x,'MatStatsAZExport'),this.ExportArray));
                end
            end
            
            outfile = fullfile(this.OutputFolder,...
                this.NameFunc{ind}(iminfo));
        end
        
    end
end
