function varargout = labelOverlay(L,cmap,skip,interpfact,doShuffle,parenth)

if nargin<5 || isempty(doShuffle)
    doShuffle = true;
end

if nargin<3 || isempty(skip)
    skip = 1;
end
if nargin<4 || isempty(interpfact)
    interpfact = skip;
end

if nargin<2 || isempty(cmap)
    cmap = jet(max(L(:)));
end

if ischar(cmap)
    cmap = feval(cmap,max(L(:)));
end

if nargin<6 || isempty(parenth)
    parenth = gca;
end

borderxy = label2outline(L,skip,interpfact);

if doShuffle
    labelidx = randperm(numel(borderxy));
else
    labelidx = (1:numel(borderxy))';
end

for jj = numel(borderxy):-1:1
    % take the nearest colour
    colidx = 1 + ceil((size(cmap,1)-1)*(labelidx(jj)-1)/(max(numel(borderxy),2)-1));
    col = cmap(colidx,:);
    ph(jj) = patch('xdata',borderxy{jj}(:,2),'ydata',borderxy{jj}(:,1),...
        'edgecolor',col,'facecolor',col,'parent',parenth,...
        'linewidth',1.5,'facealpha',0);
end

if nargout>0
    varargout{1} = ph;
end
