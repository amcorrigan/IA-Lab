classdef RingIntensityAZMeasure < AZMeasure
    % Measure intensity in rings inside and outside the nucleus (or other objects).
    properties
        BorderWidth % this is width of the boundary to exclude either side, for when not sure whether in or out.
        InternalWidths
        ExternalWidths
        % these could potentially be vectors
    end
    methods
        function this = RingIntensityAZMeasure(propPrefix,bwidth,inwidth,outwidth)
            % might be possible to do the widths like Columbus, ie in
            % fractions of the region size, perhaps using the distance
            % transform.  to run at reasonable speed, this would rely on
            % the regions being separated, eg by watershed lines.
            if nargin<1 || isempty(propPrefix)
                propPrefix = '';
            end
            
            this = this@AZMeasure(propPrefix);
            
            this.ExternalWidths = outwidth;
            this.InternalWidths = inwidth;
            this.BorderWidth = bwidth;
        end
        
        function [stats,varargout] = measure(this,L,imdata)
            % can be one or two labels, the first is the region of
            % interest, the second should be a larger containing region
            % which constrains the outer boundary
            
            % start off with something basic but functional
            if ~iscell(L)
                L = {L};
            end
            if ~iscell(imdata)
                imdata = {imdata};
            end
            
            
            % let's assume that the regions are separated
            Din = bwdist(L{1}==0);
            Dout = bwdist(L{1}>0);
            
            % need to assign the outer region to the appropriate label
            outerdist = max(this.ExternalWidths);
            
            Dbasin = min(Dout,2*outerdist - Dout);
            
            bg = Dout>=(outerdist+3); % might be able to make the 3 a bit smaller..
            
            Lfull = markerWatershed(Dbasin,L{1}>0,bg);
            Lfull = matchLabels(Lfull,L{1});
            
            % run the outer and inner separately for clarity of later
            % analysis
            
            outdistances = [this.BorderWidth;this.ExternalWidths(:)];
            indistances = [this.BorderWidth;this.InternalWidths(:)];
            
            for jj = 1:numel(imdata)
                for ii = 1:(numel(indistances)-1)
                    tempL = Lfull.*(Din>indistances(ii) & Din<=indistances(ii+1));

                    tstats1 = regionprops(tempL,imdata{1},'MeanIntensity','Area');
                    tstats2 = regionprops(tempL,double(imdata{jj}).^2,'MeanIntensity');

                    mfield = sprintf('Inner%dMeanCh%d',ii,jj);
                    sfield = sprintf('Inner%dStdevCh%d',ii,jj);

                    [stats(1:numel(tstats1),1).(mfield)] = tstats1.MeanIntensity;

                    sdevdata = cellfun(@(x,y) sqrt(x - y.^2),...
                        {tstats2.MeanIntensity}',{tstats1.MeanIntensity}','uni',false);
                    [stats(1:numel(tstats1),1).(sfield)] = sdevdata{:};
                    
                    if jj==1
                        [stats(1:numel(tstats1),1).(sprintf('Inner%dPixArea',ii))] = ...
                            tstats1.Area;
                    end
                end

                for ii = 1:(numel(outdistances)-1)
                    tempL = Lfull.*(Dout>outdistances(ii) & Dout<=outdistances(ii+1));
                    if numel(L)>1
                        tempL(tempL~=L{2}) = 0;
                    end

                    tstats1 = regionprops(tempL,imdata{jj},'MeanIntensity','Area');
                    tstats2 = regionprops(tempL,double(imdata{jj}).^2,'MeanIntensity');

                    mfield = sprintf('Outer%dMeanCh%d',ii,jj);
                    sfield = sprintf('Outer%dStdevCh%d',ii,jj);

                    [stats(1:numel(tstats1),1).(mfield)] = tstats1.MeanIntensity;

                    sdevdata = cellfun(@(x,y) sqrt(x - y.^2),...
                        {tstats2.MeanIntensity}',{tstats1.MeanIntensity}','uni',false);
                    [stats(1:numel(tstats1),1).(sfield)] = sdevdata{:};
                    
                    if jj==1
                        [stats(1:numel(tstats1),1).(sprintf('Outer%dPixArea',ii))] = ...
                            tstats1.Area;
                    end
                end
            end
            
            if ~isempty(this.Prefix)
                stats = prefixFields(stats,this.Prefix);
            end
            
        end
        
    end
end
