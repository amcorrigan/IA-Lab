classdef CollapsePanel < uix.BoxPanel
    % a collapsible box panel
    % this is designed to go into a GUI, rather than being a standalone
    % figure
    % to begin with, this is expected to be inside a vbox, or at least
    % something which specifies the heights
    
    properties
        PrefHeight = -1;
        CollapsedHeight = 20;
    end
    methods
        function this = CollapsePanel(prefHeight,varargin)
            this = this@uix.BoxPanel(varargin{:});
            
            if nargin>0 && ~isempty(prefHeight)
                this.PrefHeight = prefHeight;
            end
            set(this,'MinimizeFcn',@this.toggleMinimised)
            
            this.setHeights();
        end
        
        function toggleMinimised(this,src,evt)
            this.Minimized = ~this.Minimized;
            this.setHeights();
        end
        
        function setHeights(this)
            parh = get(this,'parent');
            if ~isempty(parh)
                % find out which child is this one
                % for some reason, children is the reverse order to
                % heights.. that's just daft..
                
                idx = flipud(get(parh,'children')==this);
                
                hvals = get(parh,'heights');
                if this.Minimized
                    hvals(idx) = this.CollapsedHeight;
                else
                    hvals(idx) = this.PrefHeight;
                end
                set(parh,'heights',hvals);
            end
        end
    end
end
