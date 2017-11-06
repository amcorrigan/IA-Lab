classdef GridIconStor < IconStor
    % this version reads the whole image into memory and then returns the
    % appropriate tile when necessary
    properties
        imData;
        tileSiz
        tileDim
        offset
    end
    methods
        function obj = GridIconStor(filename,tileSiz,offset,tileDim)
            if ischar(filename)
                obj.imData = imread(filename);
            else
                obj.imData = filename;
            end

            obj.tileSiz = tileSiz;
            if nargin<4 || isempty(tileDim)
                tileDim = floor(size(obj.imData)./obj.tileSiz);
            end
            if nargin>2 && ~isempty(offset)
                obj.offset = offset;
            end

            obj.tileDim = tileDim;
        end

        function im = getImage(obj,idx)
            [c,r] = ind2sub(obj.tileDim([2,1]),idx);

            im = obj.imData(obj.offset(1)+(r-1)*obj.tileSiz(1)+(1:obj.tileSiz(1)),...
                obj.offset(2)+(c-1)*obj.tileSiz(2)+(1:obj.tileSiz(2)),:);
        end

        function N = getNumImages(obj)
            N = prod(obj.tileDim);
        end
    end
end
