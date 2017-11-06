classdef SemicolonSeparatedAZExport < AZExport
    % export of structure to colon-separated-value format
    properties
%         FileName % this should be removed
        Settings = [];
    end
    methods
        function this = SemicolonSeparatedAZExport(settings)
% %             if nargin>0 && ~isempty(filename)
% %                 this.FileName = filename;
% %             end
            if nargin>0 && ~isempty(settings)
                this.Settings = settings;
            end
        end
        
        function flag = export(this,stats,doAppend,fileName,newsettings)
% %             if nargin>3 && ~isempty(newFileName)
% %                 this.FileName = newFileName;
% %             end
            if nargin<3 || isempty(doAppend)
                doAppend = true;
            end
            
            if doAppend
                permissionstr = 'at+';
            else
                permissionstr = 'wt+';
            end
            
            try
            foldername = fileparts(fileName);
            if ~exist(foldername,'dir')
                mkdir(foldername)
            end
            catch ME
                rethrow(ME)
            end
            
            fid = fopen(fileName,permissionstr);
            
            if fid<1
                error('Can''t open file for writing')
            end
            
            if nargin>4 && ~isempty(newsettings)
                this.Settings = newsettings;
            end
            
            stats = prepareForExport(stats,this.Settings);
            
            fnames = fieldnames(stats);
            
            headstr = this.getHeaderString(fnames);
            
            s = dir(fileName);
            if s.bytes==0 || ~doAppend
                % need to add the column headings
                fprintf(fid,[headstr,'\n']);
            else
                % need to check that the column headings match up
                val = fseek(fid,0,'bof');
                firstLine = fgetl(fid);
                if ~strcmp(firstLine,headstr)
                    error('Data in structure and file don''t match')
                end
                
                val = fseek(fid,0,'eof');
            end
            
            cellstats = cellfun(@num2str,struct2cell(stats),'uni',false);
            
            for ii = 1:size(cellstats,2)
                linestr = sprintf('%s;',cellstats{:,ii});
                
%                 % see if doubling up the backslashes works
%                 linestr = regexprep(linestr,'\\{1}([^n])','\\\\$1');
                linestr = strrep(linestr, '\', '\\');
                linestr = [linestr(1:end-1),'\n'];
                
                fprintf(fid,linestr);
            end
            
            flag = fclose(fid);
            
        end
        
        function headstr = getHeaderString(this,fnames)
            
            headstr = sprintf('%s;',fnames{:});
            headstr = headstr(1:end-1);
        end
    end
end