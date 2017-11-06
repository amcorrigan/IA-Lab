classdef SemicolonTranslateAZExport < SemicolonSeparatedAZExport
    % Include a possible translation between the short fieldnames of the
    % stats structure, and wordier explanations that we want to appear in
    % the spreadsheet headers
    properties
        ConversionArray
    end
    methods
        function this = SemicolonTranslateAZExport(settings,CA)
            if nargin>0 && ~isempty(settings)
                this.Settings = settings;
            end
            
            if nargin<2 || isempty(CA)
                CA = this.definiensConversion();
            end
            
            if ischar(CA)
                switch lower(CA)
                    otherwise
                        CA = @this.autoConvert;
                end
            end
            
            this.ConversionArray = CA;
        end
        
        
        function headstr = getHeaderString(this,fnames)
            if iscell(this.ConversionArray)
                for ii = 1:numel(fnames)
                    ind = find(strcmpi(fnames{ii},this.ConversionArray(:,1)),1,'first');
                    if ~isempty(ind)
                        fnames{ii} = this.ConversionArray{ind,2};
                    end
                end
                headstr = sprintf('%s;',fnames{:});
            else
                % other option is a function handle which converts the
                % input field names into the header string (which can have
                % spaces)
                outnames = cellfun(this.ConversionArray,fnames,'uni',false);
                
                % The line above is equivalent to this loop
% %                 outnames = cell(size(fnames));
% %                 for ii = 1:numel(fnames)
% %                     outnames{ii} = this.ConversionArray(fnames{ii});
% %                 end
                
                headstr = sprintf('%s;',outnames{:});
            end
        end
    end
    
    methods (Static)
        function CA = definiensConversion()
            % put the fields in the order they're expected, to see if we
            % can sort that as well?
            CA = {'ObjectCount','No. of Cell';...
                'SpotCytoArea','Mean Area of Spots in Cytoplasm of Cell';...
                'SpotNucIntensity','Mean Total Spot Intensity in Nucleus of Cell';...
                'QCBlur','QC_LargeBlurredRegions'};
        end
        
        function outstr = autoConvert(instr)
            % try to convert the name by putting a space before each
            % capital letter (except the first), and expanding common
            % abbreviations (take care here not to assume too much)
            
            
            
        end
        
    end
end
