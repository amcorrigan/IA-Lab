function ph = pointOverlay(xyz,cmap,parenth,maxz,marker)

if nargin<5 || isempty(marker)
    marker = 'o';
end
if nargin<4 || isempty(maxz)
    maxz = max(xyz(:,3));
end


if ~isempty(xyz) && ~(isscalar(cmap) && isnan(cmap))
    if size(cmap,1)==1
        % single colour
        try
        usemap = linspace(0.5,1,255)' * cmap;
        catch ME
            rethrow(ME)
        end
    else
        usemap = cmap;
    end

    % unlike with the region-based visualisation, we don't
    % need a separate graphics object for each identified
    % point; they can be merged into, say, 20 colours
    if size(xyz,2)<3
        colind = ceil(20*rand(size(xyz,1),1));
    else
        colind = max(1,min(20,ceil(20*xyz(:,3)/maxz)));
    end

    for jj = 1:20
        mapind = ceil(size(usemap,1)/20 * jj);
        currinds = colind==jj;
        if nnz(currinds)>0
            xdata = xyz(currinds,2);
            ydata = xyz(currinds,1);
        else
            xdata = NaN;
            ydata = NaN;
        end
        ph(jj) = line('parent',parenth,'xdata',xdata,...
                'ydata',ydata,'marker',marker,'color',usemap(mapind,:),...
                'markersize',4,'linestyle','none');
    end

end