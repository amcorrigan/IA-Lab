classdef FastDoGProc2 < ImProcND
    % 2D DoG filter
    % For the 2D case, can use the optimized MATLAB imresize function
    % with the default (currently hard coded) downscaling, provides a speed
    % up of more than order of magnitude for widths ~50
    
    % the effect of this is basically that the kernel is always the same,
    % and the image is scaled to a reference size
    % NOT QUITE! If the width in one dimension is small (smaller than 4
    % say?) then it isn't scaled.
    % also, is it worth having a minimum factor by which the image should
    % be scaled?  Rather than having a kernel of 5 being downscaled to 4.
    % Factor of 2?  Since this is only really supposed to be used for very
    % large kernels
    
    % Still seems to be faster to permute the image and always filter in
    % the x direction, rather than pass a 2D or 3D kernel - THEREFORE all
    % the kernels are stored as column vectors, and the indices tell us
    % which dimension this is over
    
    % The benefit of doing this for a DoG would seem to be that only one
    % resizing operation needs to be done for the two filters (seeing as
    % how this is the slow part)
    % Therefore, one wouldn't want to separately scale for each size, since
    % that would negate any benefit
    % So for maximum flexibility, allow several widths to be provided (as
    % rows of matrix), but choose the image scaling based on the smallest
    % sized kernel
    
    properties
        widths0 % the width of the Gaussian on the unscaled image (ie directly provided by user)
        
        scfact
        kArraySc % Sc at the end to ensure we know that this is for the downscaled image
        
        boundCon = 'replicate';
        
        diffstep = 1; % by default, subtract one filter from the next
    end
    properties (Hidden)
        % this could be hardcoded if desired
        widratio = 3
        
        noScaleLimit = 6;
    end
    
    methods
        function obj = FastDoGProc2(wids,diffstep,boundcon)
            if nargin>2 && ~isempty(boundcon)
                obj.boundCon = boundcon;
            end
            
            if nargin>1 && ~isempty(diffstep)
                obj.diffstep = diffstep;
            end
            
            if isvector(wids)
                wids = wids(:)*[1,1];
            end
            obj.widths0 = wids;
            
            obj.kArraySc = cell(size(obj.widths0));
            
            % zeros could interfere with this, but a zero should propagate
            % because it's the same image we want to use for every filter
            minwids = min(obj.widths0,[],1); % it's the minimum scale that is used to decide the downscaling
            
            for ii = 1:numel(minwids)
                % compute the scale factor and the kernel
                if minwids(ii)>obj.noScaleLimit
                    obj.scfact(ii) = minwids(ii)/obj.widratio;
                else
                    obj.scfact(ii) = 1;
                end
                
                % then the kernels need calculating for each filter
                % operation
                for jj = 1:size(obj.widths0,1)
                    thiswid = obj.widths0(jj,ii)/obj.scfact(ii);
                    if thiswid>0
                        obj.kArraySc{jj,ii} = gaussKernel(thiswid,6);
                    end
                end
            end
            
            
        end
        
        function fim = process(obj,im)
            % This process needs to work slightly differently
            % the main images are calculated then have the differences
            % taken
            % This might be better implementing without the subtraction
            % first, so that custom subtraction can be setup
            % do that later..
            
            
            sizim = size(im);
            totdim = numel(sizim);
            ndim = size(obj.kArraySc,2);
            
            usescfact = ones(1,numel(sizim));
            usescfact(1:numel(obj.scfact)) = obj.scfact;
            
            pvect = 1:totdim;
            pvect(1:ndim) = [ndim,1:(ndim-1)];
            
%             tempfim = repmat({amcResize3D(im,sizim./usescfact,'downlinear')},[size(obj.kArraySc,1),1]);
            tempfim = repmat({imresize(im,ceil(sizim./usescfact))},[size(obj.kArraySc,1),1]);
            fim = cell(numel(tempfim)-obj.diffstep,1);
            
            for jj = 1:numel(tempfim)
                
    %             fim = resizen(im,sizim./usescfact);
                % work in reverse order
                for ii = ndim:-1:1
                    tempfim{jj} = permute(tempfim{jj},pvect);
                    try
                    if obj.widths0(ii)>0
                        tempfim{jj} = imfilter(tempfim{jj},obj.kArraySc{jj,ii},obj.boundCon);
                    end
                    catch ME
                        rethrow(ME)
                    end
                end
                
                % then do the subtraction at the end
                if jj>obj.diffstep
%                     fim{jj-1} = amcResize3D(tempfim{jj-1} - tempfim{jj},sizim,'linear');
                    fim{jj-1} = imresize(tempfim{jj-obj.diffstep} - tempfim{jj},sizim);
                    % and scale back
                    % the scaling could potentially be speeded up
                end
            end
            
            if numel(fim)==1
                fim = fim{1};
            end
        end
    end
    
end