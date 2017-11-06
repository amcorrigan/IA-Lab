classdef ThroughputMultiIX < ThroughputParser
    % batch processing for the multi-plate IX parser
    %
    % Rather than making lots of different batch parsers, lets try rolling
    % them all together and calling the appropriate method?
    %
    % Probably the easiest way of joining them up is to make one
    % corresponding batch parser for each parser, and then ordering them
    % sequentially, then whichever type is required, it will work?
    properties
        TpParsers = {}
        
        NumImages = [];
    end
    methods
        function this = ThroughputMultiIX(mIXParser,imagetype)
            if nargin<2 || isempty(imagetype)
                imagetype = '3DnC';
            end
            
            for ii = 1:numel(mIXParser.ParserArray)
                switch lower(imagetype)
                    % the names for the parsers are messed up at the
                    % moment, but doesn't matter because only one has been
                    % implemented
                    case {'3dnc','2dnc'}
                        this.TpParsers{ii} = ThroughputIX2DnC(mIXParser.ParserArray{ii});
                    otherwise
                        error('Unknown image type')
                end
                this.NumImages(ii) = this.TpParsers{ii}.getNumImages();
            end
            
            
            
        end
        
        function num = getNumImages(this)
            num = sum(this.NumImages);
        end
        
        function [imobj,imInfo] = getImage(this,idx)
            % from the idx, work out which parser it is we need to call
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            csum = [0,cumsum(this.NumImages(:)')];
            
            parserVal = nnz(idx>csum);
            
            adjIdx = idx - csum(parserVal);
            
            [imobj,imInfo] = this.TpParsers{parserVal}.getImage(adjIdx);
            
            % want to add the plate name to the info
            imInfo.plate = this.TpParsers{parserVal}.ParserObj.PlateName;
            
        end
        
        function imInfo = getImageInfo(this,idx)
            % from the idx, work out which parser it is we need to call
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            csum = cumsum(this.NumImages);
            
            parserVal = nnz(idx>csum) + 1;
            
            adjIdx = idx - csum(parserVal);
            
            imInfo = this.TpParsers{parserVal}.getImageInfo(adjIdx);
            
            % want to add the plate name to the info
            imInfo.plate = this.TpParsers{parserVal}.ParserObj.PlateName;
            
        end
    end
end
