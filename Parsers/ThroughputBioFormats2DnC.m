classdef ThroughputBioFormats2DnC < ThroughputParser
    
    properties
       ParserObj
        
        Indices % which indices in the well, field, timeline, timepoint grid have valid images
                % when index n is supplied, it means this.Indices(n) for
                % the linear index
        
        WellFieldOrder
                
        TSize
        WFSize
        
        
        CZVals % used to store the indices required for the 2DnC object
% %         CDimension
% %         ZDimension
% %         TDimension
        WDimension
% %         FDimension
% %         OtherDimensions
         
    end
    
    methods
        function this = ThroughputBioFormats2DnC(parserobj)
            this.ParserObj = parserobj;
            
            this.WFSize = nnz(~isnan(this.ParserObj.WellFieldMap));
            
            % for now, assume that the experiment is rectangular, ie all
            % the fields have the same number of timepoints
            this.TSize = this.ParserObj.BFReader.getSizeT();
            
            
            
            % not sure how much of the IX stuff below is required
            
            
            fnames = parserobj.ChoiceStruct.Labels;
            % want to rearrange so that thumbnail dimension is last, CZ is
            cidx = strcmpi('channel',fnames);
            zidx = strcmpi('zslice',fnames);
            tidx = strcmpi('timepoint',fnames);
            
% %             this.OtherDimensions = find(~tidx & ~cidx & ~zidx);
% %             
% %             % think the otherdimensions should be reversed to use row major
% %             % order
% %             this.OtherDimensions = fliplr(this.OtherDimensions(:)');
            
            
% %             this.CDimension = find(cidx);
% %             this.ZDimension = find(zidx);
% %             this.TDimension = find(tidx);
            
            this.WDimension = find(strcmpi('well',fnames));
%             this.FDimension = find(strcmpi('field',fnames));
            
            if isempty(zidx)
                zvals = 1;
            else
                zvals = (1:this.ParserObj.BFReader.getSizeZ())';
            end
            
            if isempty(cidx)
                cvals = 1;
            else
                cvals = (1:this.ParserObj.BFReader.getSizeC())';
            end
            
            this.CZVals = {cvals,zvals};
            
            
            
            
        end
        
        function num = getNumImages(this)
            % number of images is the number of well-fields, multiplied by
            % the number of timepoints
            
            num = this.WFSize*this.TSize;
        end
        function [imobj,imInfo] = getImage(this,idx)
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            if isempty(this.ParserObj.BFReader)
                this.ParserObj.refreshReader();
            end
            
            for ii = 1:numel(idx)
                % the parameters to iterate through are well and field, and
                % these should be stored in the WellFieldMap property
                [wfidx,tidx] = ind2sub([this.WFSize,this.TSize],idx(ii));

                % this is 3D, but we want to linearize so that the iteration
                % order is fields first followed by well
                temp = permute(this.ParserObj.WellFieldMap,[3,2,1]);
    %             temp = joinDimensions(temp,{1,[2,3]});
                temp = temp(~isnan(temp));

                seriesInd = temp(wfidx);

                this.ParserObj.BFReader.setSeries(seriesInd-1);

                % for the moment, we assume that there is only one z slice
                cvals = 1:this.ParserObj.BFReader.getSizeC();
                
                % need to work out which well and field we're looking for
                ixyz = findn(this.ParserObj.WellFieldMap==seriesInd);
                if numel(ixyz)<3
                    ixyz(3)=1;
                end
                wellval = rowcol2wellstr(ixyz(1),ixyz(2));

                fullvals = [find(strcmpi(wellval{1},this.ParserObj.ChoiceStruct.Choices{this.WDimension})),ixyz(3),tidx];

                imageLabels = this.ParserObj.getImageLabel(fullvals,'short');

                imdata = cell(numel(cvals),1);
                for jj = 1:numel(cvals)
                    imind = this.ParserObj.calcImageIndex(tidx,cvals(jj),1);
                    imdata{jj} = bfGetPlane(this.ParserObj.BFReader,imind);
                end

                chanvals = cvals;
                imobj{ii} = cImage2DnC([],[],this.ParserObj.NativeColours(chanvals),...
                    chanvals, [this.ParserObj.PixelSize, this.ParserObj.PixelSize],imageLabels{1},imdata);

                % for the info, want a structure consisting of the well, and
                % presumably plate name


                imInfo(ii) = this.ParserObj.getC2DInfo(fullvals);
            end
        end
        
        function imInfo = getImageInfo(this,idx)
            if idx>this.getNumImages()
                error('Image index outside of range')
            end
            
            [wfidx,tidx] = ind2sub([this.WFSize,this.TSize],idx);
            
            temp = permute(this.ParserObj.WellFieldMap,[3,2,1]);
%             temp = joinDimensions(temp,{1,[2,3]});
            temp = temp(~isnan(temp));
            
            seriesInd = temp(wfidx);
            
            % need to work out which well and field we're looking for
            ixyz = findn(this.ParserObj.WellFieldMap==seriesInd);
            if numel(ixyz)<3
                ixyz(3)=1;
            end
            wellval = rowcol2wellstr(ixyz(1),ixyz(2));
            
            fullvals = [find(strcmpi(wellval{1},this.ParserObj.ChoiceStruct.Choices{this.WDimension})),ixyz(3),tidx];
            % for now, the only info required is something to label the
            % image
            imInfo = this.ParserObj.getC2DInfo(fullvals);
        end
        
    end
end