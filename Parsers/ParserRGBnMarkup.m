classdef ParserRGBnMarkup < ParserTraditionalRGB
    properties
        ResultDir = [];
    end
   
    methods
        function this = ParserRGBnMarkup(fol,patt,maxdepth)
            
            this = this@ParserTraditionalRGB(fol,patt,maxdepth);
        end
        
        function setResultDir(this, i_resultDir)
            this.ResultDir = i_resultDir;
        end
        
        function anRGBnMarkup = getSelectedImage(this,ChP)
            
            idx = this.getValuesFromInputs(ChP);

            if idx == 0
                anRGBnMarkup = [];
                return;
            end;
            
            [path, name, ext] = fileparts(this.ImageTree.FileNames{idx(1)});

            anRGBnMarkup = cImageRGBnMarkup(path, [name ext], this.ResultDir, [name '_Overlay' '.jpg']);
        end
        
        function imInfo = getSelectedInfo(this,ChP)
            idx = this.getValuesFromInputs(ChP);
            
            [~,tags] = cellfun(@fileparts,this.ImageTree.FileNames(idx),'uni',false);
            
            imInfo = struct('Label',tags,'FilePath',this.getFileNames(idx),...
                'Index',idx);
        end
        
        function filestr = getFileNames(this,ChP)
            idx = this.getValuesFromInputs(ChP);
            
            filestr = this.ImageTree.FileNames{idx};
        end        
    end
    
    methods (Static)
        function parsObj = browseForFile(patt)
            if nargin<1 || isempty(patt)
                patt = '*.tif';
            end
            fol = uigetdir('', 'Please select the folder which contains the images.');

            if isequal(fol, 0)
                msgbox('Please indicate the location of the images.', 'Error', 'warn');
                parsObj = [];
                return;
            end;
            
            parsObj = ParserRGBnMarkup(fol,patt,6);
        end
    end
end