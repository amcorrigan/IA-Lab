classdef ParserTrueColour < ImgLoader
    properties
        ImageTree
        ChannelLabels % this should be shipped to ImgLoader
        
        PlatePath % this is needed for HCExplorer compatibility, will be
                  % refactored to be FolderPath or something similar
    end
    methods
        function this = ParserTrueColour(fol,patt,maxdepth)
            
            this.PlatePath = syspath(fol);
            this.ImageTree = FileTree(fol,patt,maxdepth);
            
            this.ChannelLabels = {'R';'G';'B'};
        end
        
        function imobj = getSelectedImage(this,ChP)
            idx = this.getValuesFromInputs(ChP);
            
            % generate the image object
            % need to use a separate version of the 2DnC image class for
            % this
            imobj = cell(numel(idx),1);
            for ii = 1:numel(idx)
                if idx(ii)~=0
                    [~,label] = fileparts(this.ImageTree.FileNames{idx(ii)});
                    imobj{ii} = cImage2DnC.trueColour(this.ImageTree.FileNames{idx(ii)},...
                        label);
                end
            end
        end
        
        function imInfo = getSelectedInfo(this,ChP)
            idx = this.getValuesFromInputs(ChP);
            
            [~,tags] = cellfun(@fileparts,this.ImageTree.FileNames(idx),'uni',false);
            
            imInfo = struct('Label',tags,'FilePath',this.getFileNames(idx),...
                'Index',idx);
            
        end
        
        function filestr = getFileNames(this,ChP)
            idx = this.getValuesFromInputs(ChP);
            
            filestr = cell(numel(idx),1);
            for ii = 1:numel(idx)
                if idx(ii)~=0
                    filestr{ii} = this.ImageTree.FileNames{idx(ii)};
                end
            end
        end
        
        function filestr = getPartialFileNames(this,ChP,newfolder)
            if nargin<3 || isempty(newfolder)
                newfolder = '';
            end
            
            idx = this.getValuesFromInputs(ChP);
            
            filestr = cell(numel(idx),1);
            for ii = 1:numel(idx)
                if idx(ii)~=0
                    filestr{ii} = strrep(this.ImageTree.FileNames{idx(ii)},this.PlatePath,newfolder);
                end
            end
        end
        
        function rgb = getSelectedRGB(this,ChP)
            idx = this.getValuesFromInputs(ChP);
            
            % generate the image object
            % need to use a separate version of the 2DnC image class for
            % this
            rgb = cell(numel(idx),1);
            for ii = 1:numel(idx)
                if idx(ii)~=0
                    [~,label] = fileparts(this.ImageTree.FileNames{idx(ii)});
                    rgb{ii} = imread(this.ImageTree.FileNames{idx(ii)});
                end
            end
            
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
        
        function batchObj = getBatchParser(this)
            batchObj = ThroughputTrueColour(this);
        end
        
        function N = getTotalNumChan(this)
            N=3;
        end
        
        function imobj = getCurrentEmptyImage(this,ChP)
            imobj = this.getSelectedImage(ChP);
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
            
            parsObj = ParserTrueColour(fol,patt,6);
        end
        
        function parsObj = customPattern()
            % first get the user to supply the pattern to be used
            
            fol = uigetdir('', 'Please select the folder which contains the images.');

            if isequal(fol, 0)
                msgbox('Please indicate the location of the images.', 'Error', 'warn');
                parsObj = [];
                return;
            end;
            patt = getStringGUI('Custom pattern',['Enter the pattern to find the images ',...
                'of interest (e.g. Day3*.jpg)']);
            
            if isempty(patt)
                msgbox('Please enter a valid wild card pattern','Error','warn')
                parsObj = [];
                return
            end
            
            parsObj = ParserTrueColour(fol,patt,6);
            
        end
    end
end