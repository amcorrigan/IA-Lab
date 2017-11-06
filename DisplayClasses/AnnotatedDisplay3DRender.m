classdef AnnotatedDisplay3DRender < AnnotatedDisplay3DnC
    properties
        RenderAx
        FacesVertices
        RenderPatch
        
        RotateH
        RotateButton
        
        SmoothScale = 6;
        XYDownScale = 2;
    end
    methods
        function this = AnnotatedDisplay3DRender(varargin)
            this = this@AnnotatedDisplay3DnC(varargin{:});
            
            
        end
        
        function setupDisplay(this)
            setupDisplay@AnnotatedDisplay3DnC(this);
            
            this.RenderAx = axes('parent',this.CornerPanel,'activepositionproperty','position',...
                'position',[0,0,1,1]);
            this.RotateButton = uicontrol('parent',this.CornerPanel,'style','ToggleButton',...
                'String',char(8635),'value',0,'callback',@(src,evt)this.setRotate(get(src,'value')),...
                'units','normalized','position',[0.9,0,0.1,0.1],'FontUnits','normalized',...
                'FontSize',0.9);
            
            % adjust the default positioning of the FlexGrid
            set(this.FlexGrid,'heights',[-3,-5]);
            set(this.FlexGrid,'widths',[-3,-5]);
            
        end
        
        function varargout = showImage(this,varargin)
            hh = showImage@AnnotatedDisplay3DnC(this,varargin{:});
            
            
            % to begin with, display the 3D render by default
            this.generateRendering();
            
            if nargout>0
                varargout{1} = hh;
            end
        end
        
        function generateRendering(this)
            temp = resize3(this.ImObj.LabelObj.LData{1},[1/this.XYDownScale,1/this.XYDownScale,1],'nearest');
            vals = this.ImObj.LabelObj.RPerm{1};
            
            % the colourmap isn't settable yet, but once it is this will
            % need changing
            cmap = jet(this.ImObj.LabelObj.NumLabels(1));
            
            pixsize = this.ImObj.PixelSize;
            if numel(pixsize)<3
                pixsize(3) = 1;
            end
            [x,y,z] = meshgrid(pixsize(1)*(1:size(temp,2)),pixsize(1)*(1:size(temp,1)),...
                pixsize(3)*(1:size(temp,3)));
            z = -z;
            
            % might be able to assign multiple colours within a single
            % isosurface, which might speed up the rendering?
            smoothwid = this.SmoothScale*[1,1,pixsize(1)/pixsize(3)];
            for ii = 1:max(temp(:))
                % get the colour from the colour map to match with the 
                cdata = cmap(vals(ii),:);
                
                tempbw = gaussFiltND(temp==ii,[1,1,1]);
                this.FacesVertices{ii} = isosurface(x,y,z,tempbw,0.5);
                try
                this.RenderPatch{ii} = patch(this.FacesVertices{ii},'facecolor',cdata,'edgecolor','none');
                
                catch ME
                    rethrow(ME)
                end
                
                isonormals(x,y,z,-gaussFiltND(tempbw,smoothwid),this.RenderPatch{ii});
            end
            daspect([1,1,1]);
%             axis tight
            view(3)
            camlight left
            camlight right
            lighting gouraud
            
% %             h = rotate3d(this.RenderAx);
% %             h.Enable = 'on';
% %             setAllowAxesRotate(h,this.AxXY,false);
% %             setAllowAxesRotate(h,this.AxXZ,false);
% %             setAllowAxesRotate(h,this.AxYZ,false);
        end
        
        % the rotating messes up any other mouse interactions, so want to
        % only activate the mode transiently
% %         function keypressfun(this,src,evt)
% %             % check if the key is ctrl, and if so, change the scroll mode
% %             if ~isempty(evt.Character) || isempty(evt.Modifier)
% %                 return
% %             end
% %             if numel(evt.Modifier)==1 && strcmpi(evt.Modifier{1},'control')
% %                 this.ScrollMode = 1;
% %                 set(this.FigParent,'WindowKeyReleaseFcn',@this.keyreleasefun)
% %             end
% % % %             if numel(evt.Modifier)==1 && strcmpi(evt.Modifier{1},'shift')
% % % %                 % activate the axis rotation, only for the rendered axes
% % % %                 
% % % %                 this.RotateH = rotate3d(this.RenderAx);
% % % %                 this.RotateH.Enable = 'on';
% % % %                 setAllowAxesRotate(this.RotateH,this.AxXY,false);
% % % %                 setAllowAxesRotate(this.RotateH,this.AxXZ,false);
% % % %                 setAllowAxesRotate(this.RotateH,this.AxYZ,false);
% % % %                 
% % % %                 % MATLAB doens't allow this, so gonna need a togglebutton
% % % %                 % for this instead..
% % % % %                 set(this.FigParent,'WindowKeyReleaseFcn',@this.rotatereleasefun)
% % % %             end
% %             
% %             
% %         end
        
        function setRotate(this,val)
            if val && isempty(this.RotateH)
                % it's possible to store any window callbacks here so that
                % they can be reinstated afterwards
                
                
                this.RotateH = rotate3d(this.RenderAx);
                this.RotateH.Enable = 'on';
                setAllowAxesRotate(this.RotateH,this.AxXY,false);
                setAllowAxesRotate(this.RotateH,this.AxXZ,false);
                setAllowAxesRotate(this.RotateH,this.AxYZ,false);
                
            elseif ~val && ~isempty(this.RotateH)
                this.RotateH.Enable = 'off';
                delete(this.RotateH);
                this.RotateH = [];
                
                % here's where any messed up callbacks need to be
                % reinstated
                
            end
        end
        
        
    end
end
