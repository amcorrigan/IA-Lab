classdef AmcProgMsgBar < AmcProgBar
    properties
        msgh
    end
    methods
        function obj = AmcProgMsgBar(msg,varargin)
            obj = obj@AmcProgBar(varargin{:});
            
            % then create the message uicontrol
            
            % would be better to do this without the GUI Layout tools? Or
            % will it be just as fast, since they won't need to be
            % rearranged..?
            
            if nargin<1
                msg = 'Please wait';
            end
            obj.msgh = uicontrol('style','text','parent',obj.fig,...
                'units','normalized','position',[0.05,0.5,0.9,0.4],'String',msg,...
                'FontSize',12);
        end
        
        function updateMsg(obj,msg)
            set(obj.msgh,'String',msg)
        end
        
        function setFont(obj,fontname,fontsize)
            if nargin>1 && ~isempty(fontname)
                set(obj.msgh,'FontName',fontname)
            end
            if nargin>2 && ~isempty(fontsize)
                set(obj.msgh,'FontSize',fontsize)
            end
        end
    end
end