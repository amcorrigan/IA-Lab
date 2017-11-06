classdef RegionDualSelection < handle

    events
        ApplyDefined
    end

    properties
        image    % image to work on, obj.image = theImageToWorkOn
        roi      % the generated ROI mask (logical)
        labels   % Connected component labens (multi ROI)
        number   % how many ROIs there are

        figh = 512; % initial figure height - your image is scaled to fit.
                    % On change of this the window gets resized
                    
        Mrgb     % original size of this.image
        Nrgb     % original size of this.image
    end

    properties(Access=private)
        % UI stuff
        MotherFigure    % mainwindow
          imax    % holds working area
          roiax   % holds roid preview image
          imag    % image to work on
          roifig  % roi image
          buttons
          
        figw      % initial window height, this is calculated on load
        hwar = 2.1;  % aspect ratio

        % Class stuff
        loadmask  % mask loaded from file
        mask      % mask defined by shapes
        current      %  which shape is selected
        shapes = {}; % holds all the shapes to define the mask

        % load/save information
        filename
        pathname
    end

    %% Public Methods
    methods 
        function this = RegionDualSelection(anImage, motherFigure)
        % constructor
            if nargin <= 1
                motherFigure = figure;
            end
        
            % make sure the window appears "nice" (was hard to find this
            % aspect ratio to show a well aligned UI <img src="http://desperate-engineers.com/wp-includes/images/smilies/icon_wink.gif" alt=";)" class="wp-smiley">
            this.figw = this.figh*this.hwar;

            % invoke the UI window
            this.createWindow(motherFigure);

            [this.Mrgb, this.Nrgb, ~] = size(anImage);
            
            % load the image
            if nargin > 0
                this.image = imresize(anImage, 0.2);
            else
                this.image = ones(100,100);
            end        

            % predefine class variables
            this.current = 1;
            this.shapes = {}; % no shapes at start
            this.filename = 'mymask'; % default filename
            this.pathname = pwd;      % current directory
        end

        function delete(this)
        % destructor
            delete(this.imax);
            delete(this.roiax);
            delete(this.buttons);
            
            close(this.MotherFigure);
        end 

        function set.image(this,theImage)
            this.image = im2double(theImage);
            this.resetImages;
        end

        function set.figh(this,height)
            this.figh = height;
            this.figw = this.figh*this.hwar;
            this.resizeWindow;
        end

        function roi = getROIData(this,varargin)
            % retrieve ROI Data
            roi = this.roi;
        end
        
        function setROIData(this,roi)
            this.roi = roi;
        end
        
        function loadROI(this, roi)
            this.newROI; % delete stuff
            
            this.loadmask = roi;
            this.updateROI;
        end
    end

    %% private used methods
    methods(Access=private)
        % general functions -----------------------------------------------
        function resetImages(this)
            this.newROI;

            % load images
            this.imag = imshow(this.image,'parent',this.imax);
            this.roifig = imshow(this.image,'parent',this.roiax);  

            % set masks to blank
            [M, N, ~] = size(this.image);
            
            this.loadmask = zeros(M, N);
        end
        function updateROI(this, a)
            
            [M, N, ~] = size(this.image);

            this.loadmask = imresize(this.loadmask, [M N]);
            this.mask = this.loadmask | zeros(M, N);
            
            for i = 1:numel(this.shapes)
                
                if isa(this.shapes{i}, 'impoly')
                   BWadd = this.shapes{i}.createMask(this.imag);
                   this.mask = this.mask | BWadd;
                else
                   BWdelete = this.shapes{i}.createMask(this.imag);
                   this.mask(BWdelete == true) = false;
                end
                
            end

            r = this.image(:, :, 1);
            g = this.image(:, :, 2);
            b = this.image(:, :, 3);
            
            r = r .* this.mask;
            g = g .* this.mask;
            b = b .* this.mask;
            
            set(this.roifig,'CData',cat(3, r,g,b));
        end
        function newShapeCreated(this)
            set(this.shapes{end},'Tag',sprintf('imsel_%.f',numel(this.shapes)));
            this.shapes{end}.addNewPositionCallback(@this.updateROI);
            this.updateROI;
        end
        
       % CALLBACK FUNCTIONS
       % window/figure
        function winpressed(this,h,e,type)
            SelObj = get(gco,'Parent');
            Tag = get(SelObj,'Tag');
            if and(~isempty(SelObj),strfind(Tag,'imsel_'))
                this.current = str2double(regexp(Tag,'\d','match'));
                for i=1:numel(this.shapes)
                   if i==this.current
                       setColor(this.shapes{i},'red');
                   else
                       setColor(this.shapes{i},'blue');
                   end
                end
            end
        end

        % button callbacks ------------------------------------------------
       
        function polyclick(this, h,e)
            this.shapes{end+1} = impoly(this.imax);
            this.newShapeCreated; % add tag, and callback to new shape
        end

        function freeclick(this,h,e)
            this.shapes{end+1} = imfreehand(this.imax);
            this.newShapeCreated; % add tag, and callback to new shape
        end

        function deleteclick(this,h,e)
        % delete currently selected shape
            if ~isempty(this.current) && this.current > 0
                n = findobj(this.imax, 'Tag',['imsel_', num2str(this.current)]);
                delete(n);
                % renumbering of this.shapes: (e.g. if 3 deleted: 4=>3, 5=>4,...
                for i=this.current+1:numel(this.shapes)
                    set(this.shapes{i},'Tag',['imsel_', num2str(i-1)]);
                end

                if numel(this.shapes) > 0
                    this.shapes(this.current)=[];
                end;
                
                this.current = numel(this.shapes);
                this.updateROI;
            else
                disp('first select a shape to remove');
            end
        end

        function applyClickCallback(this, h, e, varargin)
            
            tempMask = im2bw(zeros(this.Mrgb, this.Nrgb));
            resizedMask = imresize(this.mask, 5);
            
            [Mmask, Nmask] = size(resizedMask);
            
            if this.Mrgb >= Mmask && this.Nrgb >= Nmask
                tempMask(1:Mmask, 1:Nmask) = resizedMask;
            elseif this.Mrgb < Mmask && this.Nrgb < Nmask
                tempMask = resizedMask(1:this.Mrgb, 1:this.Nrgb);
            elseif this.Mrgb >= Mmask && this.Nrgb <  Nmask
                tempMask(1:Mmask, 1:this.Nrgb) = resizedMask(1:Mmask, 1:this.Nrgb);
            elseif this.Mrgb <  Mmask && this.Nrgb >= Nmask
                tempMask(1:this.Mrgb, 1:Nmask) = resizedMask(1:this.Mrgb, 1:Nmask);
            end;
                
            this.roi = tempMask;

            clear tempMask
            clear resizedMask
            
            notify(this, 'ApplyDefined');
        end        
        
        function newROI(this, h,e)
            this.mask = zeros(size(this.image));
            
            [M, N, ~] = size(this.image);
            this.loadmask = zeros(size(M, N));
            % remove all the this.shapes
            for i=1:numel(this.shapes)
                delete(this.shapes{i});
            end
            this.current = 1; % defines the currently selected shape - start with 1
            this.shapes = {}; % reset shape holder
            this.updateROI;
        end

        % UI FUNCTIONS ----------------------------------------------------
        function createWindow(this, motherFigure, w, h)

            this.MotherFigure = motherFigure;
            
            figureMaster = uix.VBox( 'Parent', motherFigure, 'Spacing', 10, 'Padding', 5, 'BackgroundColor', [1 1 1]);

            figureUp = uix.HBoxFlex( 'Parent', figureMaster, 'Spacing', 10);
            figureDown = uix.VBoxFlex( 'Parent', figureMaster, 'Spacing', 10);
            
            figureIm1 = uix.VBoxFlex( 'Parent', figureUp, 'Spacing', 10);
            figureIm2 = uix.VBoxFlex( 'Parent', figureUp, 'Spacing', 10);

            set( figureMaster, 'Heights', [-1 28]);
            set( figureUp, 'Widths', [-4 -1]);
            drawnow();
            
            hbox = uix.HBox( 'Parent', figureDown );

            %-- this is only a gap filler
            uicontrol('Parent', hbox,...
                      'style','edit',...
                      'String', 'Please select a drawing method:',...
                      'HorizontalAlignment', 'left',...
                      'Enable', 'off',...
                      'FontSize', 10,...
                      'units','pix');
            
            
            this.buttons(end+1) = uicontrol('Parent', hbox,...
                                            'style','push',...
                                            'String','+',...
                                            'units','pix',...
                                            'BackgroundColor', [0 0 1],...
                                            'ForegroundColor', [1 1 1],...
                                            'Callback', @(h,e)this.polyclick(h,e));
            this.buttons(end+1) = uicontrol('Parent', hbox,...
                                            'style','push',...
                                            'String','-',...
                                            'BackgroundColor', [1 0 0],...
                                            'ForegroundColor', [1 1 1],...
                                            'units','pix',...
                                            'Callback', @(h,e)this.freeclick(h,e));
            %-- this is only a gap filler
            uicontrol('Parent', hbox,...
                      'style','text',...
                      'units','pix');
                  
            this.buttons(end+1) = uicontrol('Parent', hbox,...
                                            'style','push',...
                                            'String','Delete',...
                                            'units','pix',...
                                            'Callback', @(h,e)this.deleteclick(h,e));
                                        
            %-- this is only a gap filler
            uicontrol('Parent', hbox,...
                      'style','text',...
                      'units','pix');
                                        
            this.buttons(end+1) = uicontrol('Parent', hbox,...
                                            'style','push',...
                                            'String','Apply',...
                                            'units','pix',...
                                            'Callback', @(h,e)this.applyClickCallback(h,e));
            %-- this is only a gap filler
            uicontrol('Parent', hbox,...
                      'style','text',...
                      'units','pix');
                                        
            set( hbox, 'Widths', [200 zeros(1, length(this.buttons) + 2) + 52 -1]);          
            
            % axes
            this.imax  = axes('parent',figureIm1,'ActivePositionProperty', 'Position');
            this.roiax = axes('parent',figureIm2,'ActivePositionProperty', 'Position');
            linkaxes([this.imax this.roiax]);

            % add listeners
            set(this.MotherFigure,'WindowButtonDownFcn',@(h,e)this.winpressed(h,e,'down'));
            set(this.MotherFigure,'WindowButtonUpFcn',@(h,e)this.winpressed(h,e,'up')) ;
        end

        function resizeWindow(this)
            [h,w]=size(this.image);
            f = w/h;
            this.figw = this.figh*this.hwar*f;

            set(this.MotherFigure,'position',[0 0 this.figw this.figh]);
            movegui(this.MotherFigure,'center');
            set(this.MotherFigure,'visible','on');
        end
    end  % end private methods
    
    methods (Static)
        function [o_RowWindow, o_figureTune] = loadRegionSelection(i_imObjRGB)
            o_figureTune = figure('MenuBar', 'none', ...
                                  'ToolBar', 'none',...
                                  'Name', ['Fine Tunning: ' i_imObjRGB.FileName],...
                                  'NumberTitle', 'off');
                              
            o_RowWindow = RegionDualSelection(i_imObjRGB.ImDataResult, o_figureTune);
        end
    end;
end
