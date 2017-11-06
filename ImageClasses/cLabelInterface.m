classdef cLabelInterface < cPixelDataInterface & matlab.mixin.Copyable

    methods (Static)
        function Lobj = autoType(L,imgObj)
            % create the label object automatically to match the type of
            % the image object.  This can be a useful shorthand for n-D
            % segmentation which is dimensionality-agnostic
            if isa(imgObj,'cImage3D') || isa(imgObj,'cImage3DnC')
                Lobj = cLabel3D(L);
            else
                Lobj = cLabel2D(L);
            end
        end
    end
end