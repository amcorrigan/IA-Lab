classdef IconStor < handle
    % Class for storage and retrieval of indexed images, eg icons
    %
    % This is intended to be a general interface for things like multi-page
    % tiffs and gifs, grids of icons
    methods
        getImage(obj,ind);
        N = getNumImages(obj);
    end
    methods (Static)
        function inds = col2roworder(siz)
            % convert the row-first indexing into column first numbers
            temp = reshape(1:prod(siz),siz)';
            inds = temp(:);
        end
    end
end
