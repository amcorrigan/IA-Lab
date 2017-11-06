classdef ScaleBarHelper < handle
    properties
        PreferredPixelLength = 150;
        Thickness = 5;
        Log10Ladder = [1,2,5];
        
        Colour = 'w';
        Location = 'bl'; % bottom left by default
    end
    methods
        function this = ScaleBarHelper(varargin)
            if nargin>0
                this.setProperties(varargin{:});
            end
        end
        
        function [pixlen,physlen] = getLengths(this,pixsize)
            % find the nearest scale on the ladder to the preferred pixel
            % length, using the pixel size of the image
            % this will depend on the current magnification as well, which
            % should already be reflected in the pixsize input
            idealphyslen = pixsize*this.PreferredPixelLength;
            
            % find the nearest ladder value to this ideal length
            physlen = this.nearestPhysLen(idealphyslen);
            pixlen = physlen/pixsize;
        end
        
        function physlen = nearestPhysLen(this,idealphyslen)
            loglen = log10(idealphyslen);
            expnt = floor(loglen);
            coeff = loglen - expnt;
            
            logladder = log10(this.Log10Ladder);
            
            distance = coeff - bsxfun(@plus,[-1;0;1],logladder(:)');
            mininds = findn(abs(distance)==min(abs(distance(:))));
            
            physlen = this.Log10Ladder(mininds(1,2)) * 10^(expnt + (mininds(1,1)-2));
            
        end
        
        function setProperties(this,varargin)
            count = 1;
            while count<=numel(varargin)
                switch lower(varargin{count})
                    case 'thickness'
                        this.Thickness = varargin{count+1};
                        count = count + 2;
                    case {'preferredpixellength','pix','pixelsize'}
                        this.PreferredPixelLength = varargin{count+1};
                        count = count + 2;
                    case {'log10ladder','ladder'}
                        this.Log10Ladder = varargin{count+1};
                        count = count + 2;
                    otherwise
                        warning('Unknown input parameter, skipping')
                        count = count +1;
                end
            end
        end
    end
end