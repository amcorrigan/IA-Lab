classdef AZExport < handle
    % Interface for exporting of results
    %
    % Fundamental method call will be:
    % flag = AZExport.export(stats)
    
    properties
        ExportType = 'table'; % assumed a spreadsheet export by default (alternative is image)
    end
    methods
        stats = export(this,stats,doAppend,filename)
        % this is only a guideline for the table-based export
        % 
        % if it's a QC image the interface is 
        % export(this,labdata,imdata,filename)
        %
        % and if it's a mat-file saving the interface is
        % export(this,S,filename)
        
    end
end
