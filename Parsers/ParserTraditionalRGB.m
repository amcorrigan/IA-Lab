classdef ParserTraditionalRGB < ImgLoader
    properties
        ImageTree
        ChannelLabels % this should be shipped to ImgLoader
        
        PlatePath % this is needed for YEMain compatibility, will be
                  % refactored to be FolderPath or something similar
    end
    methods
        function this = ParserTraditionalRGB(fol,patt,maxdepth)
            
            this.PlatePath = fol;
            this.ImageTree = FileTree(fol,patt,maxdepth);
        end
        
        function anRGBImage = getSelectedImage(this,ChP)
            
            idx = this.getValuesFromInputs(ChP);

            if idx == 0
                anRGBImage = [];
                return;
            end;
            
            [path, name, ext] = fileparts(this.ImageTree.FileNames{idx(1)});
            
            anRGBImage = cImageRGB(path, [name ext], [1,1], name);
        end
        
        function idx = getValuesFromInputs(this,ChP)
            if isa(ChP,'ChoicesGUI')
                idx = ChP.getCurrentValues();
            else
                idx = ChP;
            end
        end
        
        function ChP = getChoiceGUI(this,parenth)
            if nargin<2 || isempty(parenth)
                parenth = uipanel('parent',gfigure,'units','normalized','position',[0,0,1,1]);
            end
            ChP = ImageFolderGUI(this.ImageTree,parenth);
        end
        
        function aName = getTitle(this)
            % get the name from the Image Tree
            aName = get(this.ImageTree.Nodes(1),'Value');
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
            
            parsObj = ParserTraditionalRGB(fol,patt,6);
        end
    end
end