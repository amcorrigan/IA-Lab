classdef ThroughputYoko3DnC < ImageThroughput
    properties
        ParserObj
    end
    methods
        function this = ThroughputYoko3DnC(parserobj)
            this.ParserObj = parserobj;
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
            tags = cellfun(@(x)x.Tag,imobj,'uni',false);
            imInfo = struct('Label',tags);
        end
        
    end
end
