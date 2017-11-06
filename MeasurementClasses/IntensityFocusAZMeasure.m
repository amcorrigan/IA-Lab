classdef IntensityFocusAZMeasure < AZMeasure
    % Measure how focussed the intensity
    properties
        Transform
    end
    methods
        function this = IntensityFocusAZMeasure(propPrefix,transfunc)
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            this = this@AZMeasure(propPrefix);
            
            if nargin>1 && ~isempty(transfunc)
                this.Transform = transfunc;
            end
            
        end
        
        
        function [stats,varargout] = measure(this,L,imdata)
            
            if iscell(L)
                L = L{1};
            end
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            
%             wc=weighted centroid (using spots channel as weights)
%             bwd1=bwdist from wc
%             bwd2=bwdist from membrane
%             bwd=bwd1/(bwd1+bwd2) (between 0 and 1, small near wc, large near membrane)
%             intens=spots channel in cell / max (spots channel in cell)
%             d=mean(bwd(:).*intens(:)) (between 0 and 1, small if most intensity is near wc)
            
            
            if ~isempty(this.Transform)
                useim = this.Transform(imdata{1});
            else
                useim = imdata{1};
            end
    
            tempstats = regionprops(L,useim,'WeightedCentroid','PixelList');
            Dedge = bwdist(L==0);
            
            for ii = numel(tempstats):-1:1
                pxy = tempstats(ii).PixelList;
                cc = tempstats(ii).WeightedCentroid([1,2]);%[2,1]
                
                %%%%%%%%%% threshold test
                intens = double(useim(L==ii));
                [t,metric]=multithresh(intens,2);
%                 if metric==0
%                     keyboard
%                 end
                cc=mean(pxy(intens>t(2),:),1);
                %%%%%%%%%%%%%%
                
                centD = sqrt(sum((pxy - repmat(cc,[size(pxy,1),1])).^2,2));
                
                %edgeD = Dedge(L==ii);
                %bwd = centD./(centD + edgeD);
                bwd = centD/max(centD);
                
%                 intens = double(useim(L==ii));
%                 intens = intens/sum(intens(:));           
%                 d = sum(bwd(:).*intens(:));
%%%%%%%%%%%%%%%%%% threshold test
                d=mean(bwd(intens>t(2)),1);
                
                
                stats(ii).IntensityDispersion = d;
            end
            
            
            if ~isempty(this.Prefix)
                stats = prefixFields(stats,this.Prefix);
            end
            
            if nargout>1
                for ii = (nargout-1):-1:1
                    varargout{ii} = [];
                end
            end
        end
    end
end