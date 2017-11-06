function minimiseFigure(fig)

% shortcut for the java code required to programmatically minimize a figure
% Also, putting it into a function means that only this function needs
% changing when mathworks eventually stop using the javaframe

if nargin<1 || isempty(fig)
    fig = get(groot,'CurrentFigure');
end

if isempty(fig)
    return
end

warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
jFrame = get(handle(fig),'JavaFrame');
jFrame.setMinimized(true);