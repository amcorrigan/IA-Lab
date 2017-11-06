classdef (Abstract) ImProcND < handle & matlab.mixin.Heterogeneous
    % override the code that separates the calls based on dimensionality,
    % and point both 2D and 3D to the same function
    methods
        function fim = process2D(obj,im)
            fim = process(obj,im);
        end
        function fim = process3D(obj,im)
            fim = process(obj,im);
        end
        
        function varargout = settingsUI(obj,im)
            disp(sprintf('Interactive settings not defined for class %s, skipping.\nThe filter will still be applied',class(obj)))
            if nargout>0
                varargout{1} = process(obj,im);
            end
        end
        
        function disp(obj)
            fprintf('Image processing operation\n')
            disp@handle(obj);
        end
        
    end
    
    % don't know if this abstract part is required, but there to denote
    % that this needs to be overridden
    methods (Abstract)
        process(obj,L);
    end
    methods (Static, Sealed, Access = protected)
        function default_object = getDefaultScalarElement
            default_object = NullProc;
        end
    end
end