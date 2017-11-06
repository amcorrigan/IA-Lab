classdef ThroughputIX2DnC < ThroughputParser
    
    properties
        ParserObj
        
        Indices % which indices in the well, field, timeline, timepoint grid have valid images
                % when index n is supplied, it means this.Indices(n) for
                % the linear index
                
        MSize % used to translate the linear index to individual values of well, field, etc
        CZVals % used to store the indices required for the 2DnC object
        CDimension
        ZDimension
        OtherDimensions
        ThumbDimension
        
    end
    methods
        function this = ThroughputIX2DnC(parserobj)
            this.ParserObj = parserobj;
            M = this.ParserObj.ChoiceStruct.ImMap;
            this.MSize = ones(1,numel(this.ParserObj.ChoiceStruct.Choices));
            temp = size(M);
            this.MSize(1:numel(temp)) = temp;
            
            % for IX, want to ignore the thumbnail images, which will be
            % probably be the last column, but no guarantee of what other
            % properties are present
            
            % I think this is already 3D, not 2D!
            
            fnames = parserobj.ChoiceStruct.Labels;
            % want to rearrange so that thumbnail dimension is last, CZ is
            % second, and all the others are first.
            thumbidx = strcmpi('isthumb',fnames);
            cidx = strcmpi('channel',fnames);
            zidx = strcmpi('zslice',fnames);
            
            this.OtherDimensions = find(~thumbidx & ~cidx & ~zidx);
            
            % think the otherdimensions should be reversed to use row major
            % order
            this.OtherDimensions = fliplr(this.OtherDimensions(:)');
            
            dim2 = find(cidx | zidx);
            this.ThumbDimension = find(thumbidx);
            
            
            this.CDimension = find(cidx);
            this.ZDimension = find(zidx);
            
            % now find any that have a non-empty CZ image
            
            K = joinDimensions(M,{this.OtherDimensions(:)',dim2,this.ThumbDimension});
            
            N = any(K(:,:,1),2); % the (:,:,1) means the isthumb=0 images
                                 % the any(,2) means any channel or z image
                                 % present
            
            % technically this could also be used to find the ACZ indices
            % which have a tiff (rather than passing the whole grid)
            
            this.Indices = find(N);
            
            if isempty(zidx)
                zvals = 1;
            else
                zvals = (1:this.MSize(zidx))';
            end
            
            if isempty(cidx)
                cvals = 1;
            else
                cvals = (1:this.MSize(cidx))';
            end
            
            this.CZVals = {cvals,zvals};
            
        end
        
        function num = getNumImages(this)
            % for this 
            num = numel(this.Indices);
        end
        function [imobj,imInfo] = getImage(this,idx)
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            % translate the linear index idx to the well, timeline,
            % timepoint and field values
            % flip before and after to switch to row major index order
            
            % BUT does this also need doing at the point the Indices are
            % calculated?
            vals = amcInd2Sub(this.MSize(this.OtherDimensions),this.Indices(idx));
            fullvals = cell(size(this.MSize));
            fullvals{this.ThumbDimension} = 1;
            fullvals(this.OtherDimensions) = num2cell(vals);
            if ~isempty(this.CDimension)
                fullvals{this.CDimension} = this.CZVals{1};
            end
            if ~isempty(this.ZDimension)
                fullvals{this.ZDimension} = this.CZVals{2};
            end
            
            
            imobj = this.ParserObj.getC2DObj(fullvals);
            
            
            imInfo = this.ParserObj.getC2DInfo(fullvals);
        end
        
        function imInfo = getImageInfo(this,idx)
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            vals = amcInd2Sub(this.MSize(this.OtherDimensions),this.Indices(idx));
            fullvals = cell(size(this.MSize));
            fullvals{this.ThumbDimension} = 1;
            fullvals(this.OtherDimensions) = num2cell(vals);
            if ~isempty(this.CDimension)
                fullvals{this.CDimension} = this.CZVals{1};
            end
            if ~isempty(this.ZDimension)
                fullvals{this.ZDimension} = this.CZVals{2};
            end
            
            % for now, the only info required is something to label the
            % image
            imInfo = this.ParserObj.getC2DInfo(fullvals);
        end
        
    end
end
