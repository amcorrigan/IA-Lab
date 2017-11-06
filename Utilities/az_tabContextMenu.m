function az_tabContextMenu(source, ~, handleUIControl)
    switch source.Label
        case 'Zoom in'
            api = iptgetapi(handleUIControl);
            mag = api.getMagnification();
            api.setMagnification(mag * 2);
        case 'Zoom out'
            api = iptgetapi(handleUIControl);
            mag = api.getMagnification();
            api.setMagnification(mag * 0.5);
        case 'Fit the window'
            api = iptgetapi(handleUIControl);
            api.setMagnification(api.findFitMag());
        case 'Close Tab'
            delete(handleUIControl);
        case 'Close All'
            while isa(handleUIControl.Parent, 'uix.TabPanel') == 1
                try
                    delete(handleUIControl.Parent.Children);
                    break;
                catch
                end;
            end;
    end
end