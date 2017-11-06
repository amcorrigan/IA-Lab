function sliceshow(im3d,cmap)
    % replacement for the old stackshow function which used GUIDE and was
    % quite buggy..

    if nargin<2 || isempty(cmap)
        cmap = gray(255);
    end
    
    if islogical(im3d)
        im3d = uint8(im3d);
    end
    
%     fig = figure('Toolbar','none','MenuBar','none');
%     fig = figure('MenuBar','none');
    fig = figure;
    % can maybe look at including standard zooming and panning at some
    % point
    
    imsiz = [size(im3d,1),size(im3d,2),size(im3d,3)];
    
    dimstr = 'xyz';
    currdim = 3;
    currslice = [1,1,1];
    
    hb = uix.HBox('parent',fig);
    vb1 = uix.VBox('parent',hb);
    
    
    sliderh = uicontrol('parent',vb1,'style','slider','min',1,'max',imsiz(currdim),...
        'value',1,'callback',@slidercallback,'sliderstep',[1/imsiz(currdim),1/10]);
    
    texth = uicontrol('parent',vb1,'style','text',...
        'string',sprintf('%s=%d',dimstr(currdim),currslice(currdim)));
    
    
    vb2 = uix.VBox('parent',hb);
    
    ax = axes('parent',vb2,'activepositionproperty','outerposition',...
        'fontsize',8);
    
    controlbox = uix.HBox('parent',vb2);
    
    xybutton = uicontrol('style','pushbutton','parent',controlbox,'String','XY',...
        'callback',{@dimcallback,3});
    xzbutton = uicontrol('style','pushbutton','parent',controlbox,'String','XZ',...
        'callback',{@dimcallback,2});
    yzbutton = uicontrol('style','pushbutton','parent',controlbox,'String','YZ',...
        'callback',{@dimcallback,1});
    uix.Empty('parent',controlbox);
    uicontrol('style','text','parent',controlbox,'string','Z Scale');
    edith = uicontrol('style','edit','parent',controlbox,'string','1',...
        'callback',@editcallback);
    zaspect = 1;
    
    set(vb1,'heights',[-1,20]);
    
    set(vb2,'heights',[-1,40])
    
    set(controlbox,'widths',[-1,-1,-1,-1,80,100])
    set(hb,'widths',[50,-1])
    
    set(fig,'windowscrollwheelfcn',@scrollcallback)
    
    imh = [];
    
    updatedisplay()
    
    colormap(cmap)
    
    function updatedisplay()
        
%         xlim = get(ax,'xlim');
%         ylim = get(ax,'ylim');
        
        
        switch currdim
            case 1
                im2d = permute(squeeze(im3d(currslice(1),:,:)),[2,1]);
                ijinds = [3,2];
            case 2
                im2d = squeeze(im3d(:,currslice(2),:));
                ijinds = [1,3];
            case 3
                im2d = im3d(:,:,currslice(3));
                ijinds = [1,2];
        end
        
        imlim = [min(im3d(:)),max(im3d(:))];
        
        xyzaspect = [1,1,zaspect];
        
        if isempty(imh)
            imh = imagesc(im2d);
        else
            set(imh,'cdata',im2d)
        end
        
%         if xlim(1)==0
            xlim = [1,imsiz(ijinds(2))];
            ylim = [1,imsiz(ijinds(1))];
%         end
        
        set(ax,'clim',imlim,'xlim',xlim,'ylim',ylim);
        daspect([xyzaspect(ijinds),1])
        
    end

    function dimcallback(src,evt,dim)
        currdim = dim;
        
        % have to change the limits of the slider
        set(sliderh,'max',imsiz(currdim),'sliderstep',[1/imsiz(currdim),1/10],...
            'value',currslice(currdim))
        
        set(texth,'string',sprintf('%s=%d',dimstr(currdim),currslice(currdim)));
        updatedisplay();
        
    end

    function editcallback(src,evt)
        % check if it's a valid number, and if it is, replace the zaspect
        % value
        temp = str2double(get(src,'string'));
        if ~isnan(temp)
            zaspect = temp;
            updatedisplay()
        else
            set(src,'string',num2str(zaspect))
        end
        
    end
    
    function scrollcallback(src,evt)
        newslice = max(1,min(imsiz(currdim),currslice(currdim) - evt.VerticalScrollCount));
        
        if newslice~=currslice(currdim)
            currslice(currdim) = newslice;
            set(sliderh,'value',currslice(currdim));
            set(texth,'string',sprintf('%s=%d',dimstr(currdim),currslice(currdim)));
            updatedisplay();
        end
    end

    function slidercallback(src,evt)
        currslice(currdim) = round(get(src,'value'));
        updatedisplay();
    end

end




