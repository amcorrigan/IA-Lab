classdef ThroughputTrueColour < ThroughputParser
    % this can use the interface for ChoicesGUI
    % The basic idea of this class is to take the experimental complexity
    % and break it down so that each image unit (which could be 3D
    % multichannel) is referenced by a number, which can then be looped
    % over.
    %
    % For the general throughput handler, there will be multiple levels,
    % depending on the type of images looped over, ie process every 3D
    % image, every slice, every 3DnC, action merged, etc...
    %
    % For simplicity of calling syntax, it might be best to have separate
    % classes for each of these?
    %
    properties
        ParserObj
        
        ResultDir = [];
        
        NumImages = 0;
        
    end
    methods
        function this = ThroughputTrueColour(parserObj)
            this.ParserObj = parserObj;
            
            this.NumImages = getNumImages(this);
        end
        
        function N = getNumImages(this)
            N = numel(this.ParserObj.ImageTree.FileNames);
        end
        
        function [imobj,imInfo] = getImage(this,idx)
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            % for the truecolour parser, the idx is already the only piece
            % of information we need
            
            imobj = this.ParserObj.getSelectedImage(idx);
            
            % for now, the only info required is something to label the
            % image
% %             tags = cellfun(@(x)x.Tag,imobj,'uni',false);
% %             imInfo = struct('Label',tags,'FilePath',this.ParserObj.getFileNames(idx),...
% %                 'Index',idx);
            imInfo = this.ParserObj.getSelectedInfo(idx);
            
            % iminfo could be placed into the image object so that they can
            % be passed around as one.
            % There is an argument that this should be taken care of by the
            % normal parser, but we might want there to be a difference in
            % the information passed depending on whether it's a 3D, 2D
            % 3DnC, 3DnAC, etc..
            
            % probably want to change this so that the MxNx3 rgb image is
            % the direct output? NO! because this won't be compatible with
            % the other parsers.
        end
        
        
        
        function imInfo = getImageInfo(this,idx)
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            imInfo = this.ParserObj.getSelectedInfo(idx);
        end
        
        
        
        function createResultDir(this)
            this.ResultDir = uigetdir('Indicate a folder where you want to save results.');
        end
        
%         function delete(this)
%             delete(this.ParserObj);
%         end
        
    end
end