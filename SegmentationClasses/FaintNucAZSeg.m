classdef FaintNucAZSeg < AZSeg
    % first build of segmentation class, taking faint nuclei as an example
    %
    % The interface for interactive settings should be abstracted once it
    % has been settled on, but it basically means defining which properties
    % can be tuned
    
    properties
        NucRadius = 32 % rough radius of desired objects
        ProbThresh = 0.44 % threshold probability
        
    end
    methods
        function this = FaintNucAZSeg(nucrad,pthr)
            % set up the interactive parameter tuning
            this = this@AZSeg({'NucRadius','ProbThresh'},...
                {'Radius of Nuclei','Detection Threshold'},...
                'Faint Nuclei',1,0,1); % 1,0,1 is the default, could be left out
            
            if nargin>0 && ~isempty(nucrad)
                this.NucRadius = nucrad;
            end
            if nargin>1 && ~isempty(pthr)
                this.ProbThresh = pthr;
            end
            
        end
        
        function [L,fim] = process(this,im,~,~)
            % original working code is in faintnucseg.m
            
            % this kind of input checking can be farmed out to specialized
            % superclasses
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            % link the smoothing scale to the nuclear size
            bilatScale = max(1,this.NucRadius/8);
            blim = amcBilateral2D(sqrt(im),[],bilatScale,0.1,16,4);
            
            % perhaps the number of tiles should also be linked to the
            % nuclear size?
            J = adapthisteq(rangeNormalise(blim),'numtiles',[16,16],'cliplimit',0.01);
            
            % multiple DoG filters to get relative response at different
            % scales
            % use FastDogProc2 with factor 2 spacing as an initial test
            frads = this.NucRadius * 2.^(-2:3);
            fdp = FastDoGProc2(frads,1);

            fim = fdp.process(J);
            
            % find local maxima and remove any extended plateaus
            rmax = scaleRegionalMaxima2D(fim{3},1.6*this.NucRadius,4);
            test = imerode(rmax,diamondElement(2));
            test = imreconstruct(test,rmax);
            rmax = rmax & ~test;

            % no need to calculate this for the whole image, just for the local maxima
            pvals = (exp(fim{2}(rmax)/0.05) + exp(fim{3}(rmax)/0.05))./...
                (1 + exp(fim{1}(rmax)/0.05) + exp(fim{4}(rmax)/0.05) +  exp(fim{5}(rmax)/0.05) + exp(fim{2}(rmax)/0.05) + exp(fim{3}(rmax)/0.05));

            goodpeak = pvals>this.ProbThresh;

            % does this want to be a label matrix to avoid breaking into multiple
            % peaks?

            badmax = rmax;
            badmax(rmax) = ~goodpeak;

            bg = badmax | test;

            rmax(rmax) = goodpeak;
            
            
            % Again, the scale of the smoothing might want to be linked to
            % the scale parameter.
            gg = gaussGradient2D(J,2.5);

            L = {markerWatershed(gg,rmax,bg)};

        end
    end
    methods (Static)
        function str = getDescription()
            str = {'Segmentation of faint nuclei','',...
                ['Detect nuclei in a roughly intensity-independent manner,',...
                ' by calculating the relative response to a range of size scales.']};
        end
    end
end
    