classdef AZSeg2DSpheroid < AZSeg 

    properties
        AlgoType = 1;
    end
    
    methods
        % For use in the interactive explorer, the concrete constructors must be able
        % to be called with no inputs, but this one is the generic tuning
        % interface, which will be called by sub-classes with constant
        % inputs
        function this = AZSeg2DSpheroid()
            
            %AZSeg(params,labels,segname,ninputchan,ninputlabels,noutputlabels)
            this = this@AZSeg({'AlgoType'}, {'Algorithm Type'}, 'Bright Field Spheroid', 1, 0, 1);
        end
        
        
        % The general idea behind this is that both imObj and labObj are
        % classes.  To be as general as possible, the output is a new label
        % object distinct from the input.  One then has to decide how to
        % combine the output with the image and any existing label arrays.
        function [oL, interIm] = process(this,imData,~, ~)
            if iscell(imData)
                imData = imData{1};
            end
            
            if isinteger(imData)
                imData = im2double(imData);
            end
            
            [o_bwSpheroid, o_overlayed, detection] = this.segmentSpheroid_Dark(imData, round(this.AlgoType));
            
            oL = bwlabel(o_bwSpheroid);
            interIm = o_overlayed;
        end
        
    end
    
    methods (Access = private)
        [o_bwSpheroid, o_overlayed, detection] = segmentSpheroid_Dark(this, i_grayImage,i_imageType);
    end
    methods (Static)
        function str = getDescription()
            str = ['Segmentation of 2D spheroids in bright field images.'];
        end
    end
end