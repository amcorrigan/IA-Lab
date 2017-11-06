classdef AZSeg < handle
% interface for segmentation classes
% the main usage is L1 = this.process(im,L0)
% if this interface is followed, then this base class provides interactive tuning and
% programmatic parameter setting (eg saving and loading)

    properties (SetAccess = protected)
        ReturnType = 'region';
        nInterIm = 0;
        
        % interface for interactive parameter tuning
        Params % cell array of the class properties
        Labels % string to display
%     end
%     properties
        NumInputChannels = 1;
        NumInputLabels = 0;
        NumOutputLabels = 1;
        
        Name = 'Segmentation';
        ReturnsExtraData = false;
    end
    methods
        % For use in the interactive explorer, the concrete constructors must be able
        % to be called with no inputs, but this one is the generic tuning
        % interface, which will be called by sub-classes with constant
        % inputs
        function this = AZSeg(params,labels,segname,ninputchan,ninputlabels,noutputlabels)
            this.Params = params;
            if nargin<2 || isempty(labels)
                labels = params;
            end
            this.Labels = labels;
            
            if nargin>2 && ~isempty(segname)
                this.Name = segname;
            end
            if nargin>3 && ~isempty(ninputchan)
                this.NumInputChannels = ninputchan;
            end
            if nargin>4 && ~isempty(ninputlabels)
                this.NumInputLabels = ninputlabels;
            end
            if nargin>5 && ~isempty(ninputchan)
                this.NumOutputLabels = noutputlabels;
            end
            
        end
        
        
        % The general idea behind this is that both imObj and labObj are
        % classes.  To be as general as possible, the output is a new label
        % object distinct from the input.  One then has to decide how to
        % combine the output with the image and any existing label arrays.
        [oL,interIm] = process(this,imData,labData, keepIntermed);
        
        
        % should be possible to define this generically
        function SettingsObj = defaultSettingsUI(this,parenth)
            % need to return a fully populated SettingsAdjuster object
            
            if nargin<2 || isempty(parenth)
                parenth = gfigure();
            end
            
            [pvals,labels] = getValuesLabels(this);
            
            SettingsObj = SettingsAdjuster(parenth,labels,pvals);
        end
        
        function updateSettings(this,values)
            if isa(values,'SettingsAdjuster')
                values = values.Values;
            end
            for ii = 1:numel(values)
                if iscell(values)
                    this.(this.Params{ii}) = values{ii};
                else
                    this.(this.Params{ii}) = values(ii);
                end
            end
            
        end
        
        function varargout = saveSettings(this,jsonfile)
            % convert the current settings to JSON, and if we've supplied a
            % filename, write the string to it.
            
            Settings = this.settingsStruct;
            out = savejson(Settings); % put the class name as the parent name
            
            if nargin>1 && ~isempty(jsonfile)
                fid = fopen(jsonfile,'wt');
                fprintf(fid,out);
                fclose(fid);
            end
            
            if nargout>0
                varargout{1} = out;
            end
        end
        
        function Settings = settingsStruct(this)
            Settings.Name = class(this);
            Settings.Labels = {};
            [Settings.Values,Settings.Labels] = this.getValuesLabels();
        end
        
        function loadSettings(this,jsonstr)
            if ~strcmpi(jsonstr(1),'{')
                % it's a file name, not a JSON string
                % read the data in
                
                jsonstr = fileread(jsonstr);
                
            end
            temp = loadjson(jsonstr);
            
            % temp should contain a structure called Settings
            
            fnames = fieldnames(temp);
            
            ind = find(strcmpi(class(this),fnames),1,'first');
            
            if isempty(ind)
                error('Settings for class %s not found in file',class(this));
            end
            
            % don't really need to look at the labels, since we know it's
            % the right class
            this.updateSettings(temp.(fnames{ind}).Values);
            
        end
        
        function [pvals,labels] = getValuesLabels(this)
            pvals = zeros(numel(this.Params),1);
            for ii = 1:numel(this.Params)
                pvals(ii) = this.(this.Params{ii});
            end
            
            if ~isempty(this.Labels)
                labels = this.Labels;
            else
                labels = this.Params;
            end
        end
         
        % The settingsUI is a remnant from a previous version, but
        % something like this should be retained, providing a way for an
        % external function (eg GUI) to adjust the settings in a general
        % way
% %         function varargout = settingsUI(this,im,labData)
% %             disp('Interactive settings not defined for class %s, skipping.\nThe segmentation will still be applied',class(this))
% %             if nargout>0
% %                 varargout{1} = process(this,im,labData);
% %             end
% %         end

% %         function n = get.NumInputChan(this)
% %             n = getNumInputs(this);
% %         end
% %         function n = get.NumOutputChan(this)
% %             n = getNumOutputs(this);
% %         end
        
        function n = getNumOutputs(this)
            % this is the one that can be overridden
            n = this.NumOutputLabels;
        end
        function n = getNumInputs(this)
            % this is the one that can be overridden
            n = this.NumInputChannels;
        end
        function n = getNumLabelInputs(this)
            % the number of input labels required
            n = this.NumInputLabels;
        end
        
        function fim = processForDisplay(this,im)
            % the default processing of a given image for display of the QC
            % image.  This will be rangeNormalise for most cases, but eg
            % for the viewRNA some contrast adjustment is necessary for the
            % high dynamic range of the spot intensities
            
            if iscell(im)
                fim = cell(size(im));
                for ii = 1:numel(im)
                    fim{ii} = this.processForDisplay(im{ii}); % this could be sent
                        % to a sub-method, but is there any point?
                end
            else
% %                 fim = rangeNormalise(im);
% %                 [f,x] = imhist(im(:,:),500);
                [f,x] = hist(double(im(:)),500);
                cf = cumsum(f)/sum(f);
                lq = x(max(1,nnz(cf<=0.001)));
                uq = x(max(1,nnz(cf<=0.999)));
                fim = mat2gray(im,[lq,uq]);
            end
        end
    end
    
    methods (Static)
        function str = getDescription()
            str = 'Segmentation algorithm - full description hasn''t been added yet';
        end
    end
    
    % This won't be needed now, because multiple segmentation objects will
    % be stored in cell arrays instead of regular arrays
    methods (Static, Sealed, Access = protected)
        function default_object = getDefaultScalarElement
            default_object = BlankSegMethod;
        end
    end
end