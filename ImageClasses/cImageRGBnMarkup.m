classdef cImageRGBnMarkup < cImageRGB & matlab.mixin.SetGet
%-- the classical RGB image and Result overlayed image
    
    properties (SetAccess = protected)
        ImDataResult = [];
        
        ResultPath = [];
        ResultName = [];
    end
    methods % Constructor
        
        function this = cImageRGBnMarkup(iRawPath, iRawName, i_ResultPath, i_ResultName)
            
            rawFileName = fullfile(iRawPath, iRawName);
            [~, aTag] = fileparts(rawFileName);
            
            this = this@cImageRGB(iRawPath, iRawName, [1 1], aTag);

            if nargin == 4
                this.ResultPath = i_ResultPath;
                this.ResultName = i_ResultName;
            end

            if exist(fullfile(this.ResultPath, this.ResultName), 'file') == 2
                this.ImDataResult = imread(fullfile(this.ResultPath, this.ResultName));
            end;
        end
    end % Constructor
    
    methods % Image interface methods
        
        function flipData(this)
            for i = 1:this.NumChannel
                this.ImData = flipud(this.ImData);
                this.ImDataResult = flipud(this.ImDataResult);
            end;
        end
        
        function setResult(this,imdata)
            % ought to put input checking here!
            this.ImDataResult = imdata;
        end
        
        function varargout = showImage(this)
            dispObj = this.defaultDisplayObject();
            
            if nargout>0
                varargout{1} = dispObj;
            end
        end
        
        function dispObj = defaultDisplayObject(this, panelh, ~, ~)
            
            dispObj = DisplayRGBnMarkup(panelh);
        end        
    end
end