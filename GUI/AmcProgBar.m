classdef AmcProgBar < ProgDisplay
    % the interface for this should really be abstracted out into a parent
    % class for other styles to inherit
    properties
        fig = [];
        progAx
        ph
        prog = 0; % needs storing in case of closing the figure - maybe the calling class can take care of this?
        col1 = [0.5,0,0];
        col0 = [1,1,1];
    end
    methods
        function obj = AmcProgBar(col1,col0)
            if nargin>0 && ~isempty(col1)
                obj.col1 = col1;
            end
            if nargin>1 && ~isempty(col0)
                obj.col0 = col0;
            end
            
            % might want an option whether to initialize here or not
            initialize(obj);
        end
        function initialize(obj)
            scrsiz = get(0,'ScreenSize');
            obj.fig = gfigure('position',[scrsiz(3)/2-80,scrsiz(4)/2-80,160,180]);
            set(obj.fig,'closerequestfcn',@obj.hide)
            obj.progAx = axes('parent',obj.fig,'units','normalized',...
                'position',[0.05,0.1,0.9,0.1],'xlim',[0,1],'ylim',[0,1],...
                'xtick',[],'ytick',[],'color',obj.col0,'box','on');
            obj.ph = patch([0,0,obj.prog,obj.prog],[0,1,1,0],obj.col1,'linestyle','none');
        end
        function updateProg(obj,prog)
            if nargin>1 && ~isempty(prog)
                obj.prog = prog;
            end
            if ~ishandle(obj.fig)
                initialize(obj);
            end
            set(obj.ph,'xdata',[0,0,obj.prog,obj.prog])
            drawnow expose
        end
        
        function TF = isvalidfig(obj)
            % check if the figure is still there (ie not been closed by the
            % user)
            TF = ishandle(obj.fig);
        end
        
        function finish(obj)
            delete(obj.fig);
        end
        function updateMsg(obj,msg)
            % do nothing
        end
        
        function hide(obj,src,evt)
            set(obj.fig,'visible','off')
        end
        
        function unhide(obj)
            set(obj.fig,'visible','off')
        end
        
        function delete(obj)
            finish(obj);
        end
        
    end
end