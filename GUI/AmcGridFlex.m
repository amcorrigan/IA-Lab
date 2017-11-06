classdef AmcGridFlex < uix.GridFlex
    properties
        DragFcn
    end
    methods
        function this = AmcGridFlex(varargin)
            this@uix.GridFlex(varargin{:});
            
        end
        function setDragFcn(obj,fun)
            if isa(fun,'function_handle')
                obj.DragFcn = fun;
            else
                error('Must be valid function handle')
            end
        end
    end
    methods (Access=protected)
        function onMouseRelease(obj,~,~)
            
            onMouseRelease@uix.GridFlex(obj,[],[]);
            
            if ~isempty(obj.DragFcn)
                obj.DragFcn();
            end
            
        end
        
    end
end
