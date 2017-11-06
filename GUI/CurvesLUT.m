classdef CurvesLUT < ImProcND
    % fast contrast adjustment using a LUT
    properties
        xx = [0;1];
        yy = [0;1];
        xlim
        ylim = [0;1];
    end
    properties (Hidden)
        ylut
        npoints = 255;
    end
    methods
        function obj = CurvesLUT(xlim,npoints,xx,yy)
            if nargin>0
                obj.xlim = xlim;
            end
            if nargin>2 && ~isempty(xx)
                obj.xx = xx;
            end
            if nargin>3 && ~isempty(yy)
                obj.yy = yy;
            end
            if nargin>2 && ~isempty(npoints)
                obj.npoints = npoints;
            end
            
            generateLUT(obj);
            
        end
        function generateLUT(obj)
            % xx and yy run between 0 and 1
            
            % this is where the interpolation should take place
            
            obj.ylut = max(obj.ylim(1),min(obj.ylim(2),...
                    interp1(obj.xx,...
                    (obj.ylim(2)-obj.ylim(1))*obj.yy + obj.ylim(1),...
                    linspace(0,1,obj.npoints),'pchip')));
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
            else
                warning('Incompatible settings, not updating')
            end
            
            generateLUT(obj);
        end
        
    end
end