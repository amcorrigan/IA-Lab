function str = getStringGUI(title, msg, varargin)

    % get the user to enter a string

    if nargin<2 || isempty(msg)
        msg = 'Enter some text:';
    end
    if nargin<1 || isempty(title)
        title = 'Get text';
    end

    fig = gfigure('Name',title,'closerequestfcn',@closereqfun,varargin{:});

    vbox = uix.VBox('parent',fig);

    texth = uicontrol('style','text','String',msg,'parent',vbox);

    edith = uicontrol('style','edit','parent',vbox);

    hbox = uix.HBox('parent',vbox);
    uix.Empty('parent',hbox);

    okbutton = uicontrol('style','pushbutton','String','OK','parent',hbox,...
        'callback',{@OKcallback,fig});
    
    set(hbox,'widths',[-4,-1])
    set(vbox,'heights',[-2,-2,-1],'spacing',10,'padding',10)
    
    uiwait(fig);

    str = get(edith,'String');

    delete(fig);

end

function OKcallback(src,evt,fig)
    uiresume(fig);
end

function closereqfun(src,evt)
    if isequal(get(src, 'waitstatus'), 'waiting')
        % The GUI is still in UIWAIT, us UIRESUME
        uiresume(src);
    else
        % The GUI is no longer waiting, just close it
        delete(src);
    end

end
