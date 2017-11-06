classdef ThresholdAZSeg < AZSeg
    % Basic thresholding and labelling - don't expect this will be very useful.
    properties
        Threshold = 500;
    end
    methods
        function this = ThresholdAZSeg(thr)
            this = this@AZSeg({'Threshold'},{'Detection Threshold'});
            
            if nargin>0 && ~isempty(thr)
                this.Threshold = thr;
            end
        end
        
        function [Lobj,notUsed] = process(this,im,~,~)
            % need to define a prototype label array class first
            % the first one doesn't necessarily need to have the final
            % implementation, just the correct interface.
            
            % also need to decide whether to always return a cLabel Object
            % or whether this wrapping should be done outside by the
            % calling function.
            % this will probably depend on the level at which user
            % interaction occurs, ie if the calling function will always be
            % a level down from the user
            % at the moment makes sense that a label object is returned, so
            % that we can distinguish between image preprocessing and
            % segmentation by their output types.
            
            % standard, move to superclass
            if iscell(im)
                im = im{1};
            end
            if ~isa(im,'double')
                im = double(im);
            end
            
            
            % some segmentation might want to return intermediate images
            % for checking, better to put that in now
            notUsed = [];
            
%             im = imObj.rawdata;
            
            thr = this.Threshold;
            if isnan(thr)
                % automatically use Otsu threshold
                thr = amcGrayThresh(im);
            end
            
%             L = bwlabeln(im>thr);
            Lobj = bwlabeln(im>thr);
            
            % call a static method from the label interface to decide
            % what's the best type of label object to create
%             Lobj = cLabelInterface.autoType(L,imObj);
        end
    end
end
