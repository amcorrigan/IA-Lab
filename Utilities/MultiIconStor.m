classdef MultiIconStor < IconStor
    % this version reads the whole lot in at the start
    
    properties
        imData
        cmap
    end
    methods
        function obj = MultiIconStor(filename)
            if ischar(filename)
                [obj.imData,obj.cmap] = imread(filename);
            else
                obj.imData = filename;
                obj.cmap = [];
            end
        end
        
        function im = getImage(obj,idx)

            im = obj.imData(:,:,:,idx);
            
            try
            if ~isempty(obj.cmap)
                im = ind2rgb(im,obj.cmap);
            end
            catch ME
                rethrow(ME)
            end
        end

        function N = getNumImages(obj)
            N = size(obj.imData,4);
        end
    end
end