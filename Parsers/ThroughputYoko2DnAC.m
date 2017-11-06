classdef ThroughputYoko2DnAC < ThroughputParser
    % For the Yokogawa high throughput object, we basically want to find
    % every image above action (action, channel and z will be a single
    % image)
    properties
        ParserObj
        
        Indices % which indices in the well, field, timeline, timepoint grid have valid images
                % when index n is supplied, it means this.Indices(n) for
                % the linear index
                
        MSize % used to translate the linear index to individual values of well, field, etc
        ACZVals % used to store the indices required for the 3DnAC object
        
    end
    methods
        function this = ThroughputYoko2DnAC(parserobj,zIndex)
            if nargin<2 || isempty(zIndex)
                zIndex = 1;
            end
            
            this.ParserObj = parserobj;
            M = this.ParserObj.ChoiceStruct.ImMap;
            this.MSize = size(M);
            if numel(this.MSize)<7
                % need to make sure the full 7 dimensions have the size
                temp = ones(1,7);
                temp(1:numel(this.MSize)) = this.MSize;
                this.MSize = temp;
            end
            
            if zIndex>this.MSize(7) || zIndex<1
                error('Selected z-slice is out of range')
            end
            
            T = joinDimensions(M,{[4,3,2,1],[5,6],7}); % rearrange to be LTFW x AC x Z
            % now find any that have a non-empty ACZ image
            N = any(T(:,:,zIndex),2);
            % technically this could also be used to find the ACZ indices
            % which have a tiff (rather than passing the whole grid)
            
            this.Indices = find(N);
            
            this.ACZVals = {(1:this.MSize(5))',(1:this.MSize(6))',zIndex};
            
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
            vals = amcInd2Sub(this.MSize(4:-1:1),this.Indices(idx));
            vals = vals(:,end:-1:1);
            fullvals = [num2cell(vals),this.ACZVals(:)'];
            
            imobj = this.ParserObj.getAC2DObj(fullvals);
            
            % for now, the only info required is something to label the
            % image
            % the information is linked to the getAC3DObj, so it could
            % be returned from an additional method, eg getAC3DInfo, and
            % that way we don't need a batch parser to get access to the
            % info, required for generating the export file names
% %             tags = cellfun(@(x)x.Tag,imobj,'uni',false);
% %             imInfo = struct('Label',tags{1},...
% %                 'Well',this.ParserObj.ChoiceStruct.Choices{1}{vals(1)},...
% %                 'TimeLine',this.ParserObj.ChoiceStruct.Choices{2}(vals(2)),...
% %                 'TimePoint',this.ParserObj.ChoiceStruct.Choices{3}(vals(3)),...
% %                 'Field',this.ParserObj.ChoiceStruct.Choices{4}(vals(4)));
            imInfo = this.ParserObj.getAC2DInfo(fullvals);
        end
        
    end
end
