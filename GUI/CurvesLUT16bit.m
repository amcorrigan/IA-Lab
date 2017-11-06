classdef CurvesLUT16bit < ImProcND
    % fast contrast adjustment using a LUT
    properties
        xx = [0;1];
        yy = [0;1];
        xrange = [0,65535];% the range for which the interpolation is used, 0 or 1 outside it
        ylim = [0;1]; % by default
    end
    properties (Hidden)
        ylut
        npoints = 65536;
    end
    methods
        function obj = CurvesLUT16bit(xx,yy,xrange)
            if nargin>0 && ~isempty(xx)
                obj.xx = xx;
            end
            if nargin>1 && ~isempty(yy)
                obj.yy = yy;
            end
            if nargin>2 && ~isempty(xrange)
                obj.xrange = xrange;
            end
            
            generateLUT(obj);
            
        end
        function generateLUT(obj)
            % xx and yy run between 0 and 1 for consistency with the
            % Contrast adjustment UI (so that the Contrast Adjustment
            % doesn't need to decide)
            
            % this is where the interpolation should take place
            % transform the interrogation x values to be appropriately
            % spread around the range
            
            xsc = (linspace(0,obj.npoints,obj.npoints)-obj.xrange(1))/(obj.xrange(2)-obj.xrange(1));
            xsc(xsc>1) = 1;
            xsc(xsc<0) = 0;
            
            obj.ylut = max(obj.ylim(1),min(obj.ylim(2),...
                    interp1(obj.xx,...
                    (obj.ylim(2)-obj.ylim(1))*obj.yy + obj.ylim(1),...
                    xsc,'pchip')));
                % this shouldn't be the slow step, check that it isn't
                
                % might also want to impose 0 and 1 outside the range.
        end
        function fim = process(obj,im)
            % im is likely to be a cell array
            convertBack = false;
            if ~iscell(im)
                im = {im};
                convertBack = true;
            end
            
            if isempty(obj.xlim)
                usexlim = double([min(im{1}(:));max(im{1}(:))]);
            else
                usexlim = obj.xlim;
            end
            % the xx values are always between 0 and 1, so they need
            % scaling to xlim before interpolating
            fim = cell(size(im));
            
            for ii = 1:numel(im)
                indim = ceil(obj.npoints*(double(im{ii})-usexlim(1))/(usexlim(2)-usexlim(1)));
                indim(indim<1) = 1;
                indim(indim>obj.npoints) = obj.npoints;
                fim{ii} = obj.ylut(indim);
            end
            
            if convertBack
                fim = fim{1};
            end
        end
        
        function updateSettings(obj,pSettings)
            if isa(pSettings,'CurvesClass')
                obj.xx = pSettings.xx;
                obj.yy = pSettings.yy;
                % don't have anything for the xrange yet
            else
                warning('Incompatible settings, not updating')
            end
            
            generateLUT(obj);
        end
        
    end
end