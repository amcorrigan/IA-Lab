classdef RenderDisplay3D < cDisplayInterface
    % paste Yinhai's code into the framework
    properties
        ParentHandle
        SmoothScale = 4;
        XYDownScale = 6;
        
        DisplayMode = 'full';
        
        PatchHandle
        
        ImObj
    end
    methods
        function this = RenderDisplay3D(parenth, ~, ~)
            % most of the inputs not required, but still need to not crash
            % when 3 inputs are passed.
            
            this.ParentHandle = parenth;
            
            
        end
        
        
        function varargout = showImage(this,imObj)
            
            if nargin<2 || isempty(imObj)
                % nothing to update
                return
            end
            
            try
            if iscell(imObj)
                L = imObj{2};
                this.ImObj = cAnnotatedImage(imObj{1},imObj{2});
            else

% %                 imdata = imObj.getDataC3D();

                L = imObj.LabelObj.LData{1};
                this.ImObj = imObj;
            end
            
            
            hPanel = uipanel('Parent', this.ParentHandle, 'units','normalized', 'BackgroundColor','black');
            set(hPanel,'Position',[0 0 1 1]);
            
            
            L = resize3(L,[size(L,1),size(L,2),size(L,3)]./[this.XYDownScale,this.XYDownScale,1],'nearest');
            L = upscaleZLabel(L,this.SmoothScale,this.SmoothScale/2);
            
            if isa(imObj,'cAnnotatedImage') && numel(imObj.ImObj.PixelSize)==3
                pixsize = imObj.ImObj.PixelSize;
                pixsize = pixsize.*[1/this.XYDownScale,1/this.XYDownScale,this.SmoothScale];
            else
               	pixsize = [1,1,1];
            end

        %%___________________________________________________
        %%
            [mL, nL, zL] = size(L);

            x = 1:nL;    %-- note this is "n"
            y = 1:mL;    %-- note this is "m"
            z = 1:zL;
            [XL, YL, ZL] = meshgrid(x, y, z);
        %%___________________________________________________
        %%
            axes1 = axes('Parent',hPanel,...
                        'Color',[0 0 0],...
                        'ZColor',[1 1 0],...
                        'YColor',[1 1 0],...
                        'XColor',[1 1 0],...
                        'MinorGridColor',[1 1 1],...
                        'GridColor',[0.75 0.75 0],...
                        'boxstyle', 'full');

            axis ij;
            view(axes1,[-32.5 28]);

            cmap = autumn(max(L(:))); % always jet for now..
            cmap = cmap(randperm(size(cmap,1)),:);

            for ii = 1:size(cmap,1)
                if nnz(L==ii)
                    [faces, verts, ~] = isosurface(XL, YL, ZL, L==ii, 0, L==ii);
                    this.PatchHandle(ii) = patch('Vertices', verts,...
                          'Faces', faces, ... 
                          'FaceColor', cmap(ii,:),... 
                          'edgecolor', 'none',...
                          'parent', axes1, ...
                          'FaceAlpha', 0.95);
                else
                    this.PatchHandle(ii) = NaN;
                end
            end;
            
            
            
            view(3);

            if strcmp(this.DisplayMode, 'Full') == 1
                xlim(axes1, [1, nL]);
                ylim(axes1, [1, mL]);
                zlim(axes1, [1, zL]);
            else
                axis tight
            end;


            grid(axes1,'on');
            grid(axes1,'minor');
            box(axes1,'on');

            zlabel('z');
            ylabel('y');
            xlabel('x');
            
            daspect(axes1,[1,1,1])
            axes(axes1);
            
            camlight 
            lighting gouraud
            rotate3d(axes1,'on')

            
            if nargout>0
                varargout{1} = this.PatchHandle;
            end
            catch ME
                rethrow(ME)
            end

        end
        
        function imObj = getImObj(this)
            % seems trivial, but required for other viewers
            imObj = this.ImObj.ImObj;
% %             imObj = [];
        end
        function colourCallback(this,src,evt,ch,ind)
            % don't need to do anything here..
            return
        end
        
    end
end
