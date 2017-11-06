classdef MatLabelAZExport < AZExport
    properties
        VarName
        Settings % settings isn't used yet, but is expected for the interface
    end
    methods
        function this = MatLabelAZExport(varname,settings)
            this.ExportType = 'mat'; % although not being exported as an image, the data save is image-based
            % labelling as 'Image' ensures that the export manager supplies
            % the class with the correct inputs
            
            if nargin<1 || isempty(varname)
                varname = 'labelData';
            end
            
            this.VarName = varname;
        end
        function export(this,labdata,imdata,filename)
            % basically save directly to the file
            % we can call it whatever we want here, perhaps that should be
            % an option in the constructor?
            
            S = struct;
            S.(this.VarName) = labdata;
            
            saveinputs = {filename;'-struct';'S'};
            
            % for now, append by default
            if exist(filename,'file')
                saveinputs = [saveinputs;{'-append'}];
            end
            
            
            % need to check that the folder exists first
            foldername = fileparts(filename);
            if ~exist(foldername,'dir')
                mkdir(foldername)
            end
            save(saveinputs{:});
        end
    end
end
