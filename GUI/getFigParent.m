function figh = getFigParent(obj,maxCount)

if nargin<2 || isempty(maxCount)
    maxCount = 50;
end

count = 0;
figh = obj;
while ~isa(figh,'matlab.ui.Figure')
    figh = get(figh,'parent');
    count = count + 1;
    if count>maxCount
        figh = matlab.ui.Figure.empty;
        return
    end
end