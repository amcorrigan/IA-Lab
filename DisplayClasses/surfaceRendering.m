function [fv,ph] = surfaceRendering(L,pixsize,xydnsc,noDisplay)

if nargin<4 || isempty(noDisplay)
    noDisplay = false;
end

if size(L,3)==1
    L = cat(3,zeros(size(L)),L);
end

sizL = [size(L,1),size(L,2),size(L,3)];

temp = resize3(L,ceil(sizL.*[xydnsc,xydnsc,1]))>0.5;

[x,y,z] = meshgrid(pixsize(1)/xydnsc*(1:size(temp,2)),pixsize(1)/xydnsc*(1:size(temp,1)),...
            pixsize(3)*(1:size(temp,3)));

z = -z;

cmap = jet(max(L(:)));

vals = randperm(max(L(:)));

smoothwid = 6*[1,1,pixsize(1)/pixsize(3)];
% % fv = [];
ph = [];
% for ii = 1:max(temp(:))
    % get the colour from the colour map to match with the 
    cdata = cmap(vals(1),:);

    tempbw = gaussFiltND(temp,[1,1,1]);
    
    % this will throw an error if temp is only 2D
    % need to come up with a way around this!
    % Currently, the absolute position of the isosurface isn't used, so we
    % can put an layer of zeros below the slice
    % Best to do that above.
    
% %     fv{ii} = isosurface(x,y,z,tempbw,0.5);
    fv = isosurface(x,y,z,tempbw,0.5);
    
    if ~noDisplay
        try
% %         ph{ii} = patch(fv{ii},'facecolor',cdata,'edgecolor','none');
        ph = patch(fv,'facecolor',cdata,'edgecolor','none');

        catch ME
            rethrow(ME)
        end

        isonormals(x,y,z,-gaussFiltND(tempbw,smoothwid),ph);
    end
% % end

if ~noDisplay
    daspect([1,1,1]);
    %             axis tight
    view(3)
    camlight left
    camlight right
    lighting gouraud
end
                      