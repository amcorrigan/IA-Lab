classdef LabelMorphAZSeg < AZSeg
    % Expansion or contraction of label regions from the boundary
    properties
        Type = 'Pixels';
        Amount = -4;
    end
    methods
        function this = LabelMorphAZSeg(amount,sctype)
            this@AZSeg({'Amount'},{'Expansion or contraction amount'},...
                'Expand or contract',0,1,1);
            
            if nargin>1 && ~isempty(sctype)
                this.Type = sctype;
            end
            
            if nargin>0 && ~isempty(amount)
                this.Amount = amount;
            end
            
        end
        
        function L = process(this,~,labdata)
            if iscell(labdata)
                labdata = labdata{1};
            end
            
            % for now, assume that none of the labels are touching
            % need a general method for when they are!
            
            % By using the distance transform rather than morphological
            % operations, the expansion can be done relative to region size
            % (ie expand by 10%, etc)
            
            if this.Amount>0
                % dilation isn't quite as straightforward as erosion,
                % because regions start to touch and must keep the boundary
                if strcmpi(this.Type,'relative')
%                     error('Relative expansion not completed yet')
                    
                    % For this, need to watershed the whole area before
                    % scaling the distance transform according to which
                    % region it falls in.
                    Dout = bwdist(labdata>0);
                    DL = matchLabels(watershed(Dout),labdata);
                    
                    Din = bwdist(labdata==0);
                    temp = regionprops(labdata,Din,'MaxIntensity');
                    regionPeaks = propimage(DL,[temp.MaxIntensity]',10);
                    
                    Dout = Dout./regionPeaks;
                    L = DL.*(Dout<=this.Amount);
                else
                    
                    D = bwdist(labdata>0);
                    bg = D>(this.Amount+2) & ~imdilate(labdata>0,true(3));

                    D(D>this.Amount) = max(0,2*this.Amount - D(D>this.Amount));

                    L = markerWatershed(D,labdata>0,bg);
                    L(D>this.Amount) = 0;
                end
            else
                % for erosion, make a choice here that a region can't
                % disappear.
                D = bwdist(labdata==0);
                
                % might be quicker to only do this if any regions disappear
                % but only if the check if quicker than the calculation..
                temp = regionprops(labdata,D,'MaxIntensity');
                regionPeaks = propimage(labdata,[temp.MaxIntensity]',10);
                peakbw = D>=regionPeaks;
                
                if strcmpi(this.Type,'relative')
                    D = D./peakbw;
                end
                
                L = labdata;
                L(~(D>abs(this.Amount) | peakbw)) = 0;
                
                % Be careful here, erosion can cause splitting of regions
                % the label should stay the same for each, but subsequent
                % labelling operations might not be aware of this!
            end
            
            % can't decide whether outputting as a cell or not is the best
            % interface..
            L = {L};
        end
    end
end
