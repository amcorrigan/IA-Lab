classdef MatStatsAZExport < AZExport
    properties
        VarName
        Settings % settings isn't used yet, but is expected for the interface
    end
    methods
        function this = MatStatsAZExport(varname,settings)
            this.ExportType = 'table'; 
            
            if nargin<1 || isempty(varname)
                varname = 'stats';
            end
            
            this.VarName = varname;
        end
        function export(this,stats,doAppend,filename)
            % basically save directly to the file
            % we can call it whatever we want here, perhaps that should be
            % an option in the constructor?
            
            % first check to see if there is an existing file with the
            % correct variable name
            % the .mat extension gets added automatically during save, but
            % to make sure the filename matches, add it explicitly here
            if ~strcmpi('.mat',filename(end-3:end))
                filename = [filename,'.mat'];
            end
            
            if exist(filename,'file')
                Sprev = load(filename);
            else
                Sprev = struct;
            end
            
            if numel(fieldnames(Sprev))>0
                
                if ~iscell(stats)
                    try
                        prevstats = Sprev.(this.VarName);

                        stats = [prevstats(:); stats(:)];
                    catch ME
                        warning('can''t string structures together, overwriting')

                    end
                else
                    try
                        tname = this.VarName;
                        tname(1) = upper(tname(1));
                        
                        iname = ['sc' tname];
                        prevIStats = Sprev.(iname);
                        stats{1} = [prevIStats(:);stats{1}(:)];
                        
                        fname = ['field' tname];
                        prevFStats = Sprev.(fname);
                        stats{2} = [prevFStats(:);stats{2}(:)];
                        
                        
                    catch ME
                        warning('can''t string structures together, overwriting')
                    end
                end
            end
            
            S = struct;
            if ~iscell(stats)
                S.(this.VarName) = stats;
            else
                tname = this.VarName;
                tname(1) = upper(tname(1));

                iname = ['sc' tname];
                fname = ['field' tname];
                
                S.(iname) = stats{1};
                S.(fname) = stats{2};
            end
            
            saveinputs = {filename;'-struct';'S'};
            
            % since we know that it's a stats structure, we can append to
            % the actual structure if we like
            % try that first
            
            
            % for now, append by default
            if exist(filename,'file')
                saveinputs = [saveinputs;{'-append'}];
            end
            foldername = fileparts(filename);
            if ~exist(foldername,'dir')
                mkdir(foldername)
            end
            
            save(saveinputs{:});
        end
    end
end

