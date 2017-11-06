function J = adaptHistEq3D(im,ntiles,clip,dist)

% trial version of 3D adaptive histogram equalization.

% first need to break up the image into tiles

imsiz = size(im);

% warnings keep getting thrown up about non-integer operands being used
% with the colon operator when we switch to the interpolation tiles.  Look
% into this at some point but seems like one way to avoid it would be to
% impose the requirement that the tilesiz is even?
% tilesiz = ceil(imsiz./ntiles);

% make it ceil so that the whole image is always covered
tilesiz = 2*ceil(0.5*imsiz./ntiles);

% recalculate the number of tiles based on the tile size that we have to
% use
ntiles = ceil(imsiz./tilesiz);

if nargin<4 || isempty(dist)
    dist = 'uniform';
end
if nargin<3 || isempty(clip)
    clip = 0.01;
end

tpoints = cell(ntiles + 2);

nbins = max(256,2/clip);

im = rangeNormalise(im);
x = ((1:nbins)')/nbins;

J = zeros(size(im));

% the positions of these fracs values might be all we need to define the
% shape of the output histogram?
% fracs = linspace(0,1,50)';

for ii = 1:ntiles(1)
    for jj = 1:ntiles(2)
        for kk = 1:ntiles(3)
            % get the histogram for the tile
            tileim = im(1+(ii-1)*tilesiz(1):min(imsiz(1),ii*tilesiz(1)),...
                1+(jj-1)*tilesiz(2):min(imsiz(2),jj*tilesiz(2)),...
                1+(kk-1)*tilesiz(3):min(imsiz(3),kk*tilesiz(3)));
            
            % in order to do the contrast-limited part, it's easier to have
            % a histogram rather than a cumulative frequency.
            
% %             thist = zeros(nbins,1);
% %             tg = ceil(nbins*tileim(:));
% %             for ll = 1:nbins
% %                 thist(ll) = nnz(tg==ll);
% %             end
            
            % use accumarray instead to speed things up
            % might be possible to speed up further by precalculating some
            % of this stuff - eg if ones(numel(tileim),1) is the same every
            % time (which it isn't) and ceil(nbins* could be done outside
            % all the loops.
            thist = accumarray(max(1,ceil(nbins*tileim(:))),ones(numel(tileim),1),[nbins,1]);
            
            excess = 1;
            phist = thist/numel(tileim);
            
            while(excess>0.01)
                excess = sum(phist(phist>clip)-clip);
                phist(phist>clip) = clip;
                phist = phist + excess/nbins;
            end
            
            switch lower(dist)
                case {'exp','exponential'}
                    tpoints{ii+1,jj+1,kk+1} = min(-1/(4.5)*log(1 - cumsum(phist)),1);
                case {'sig','sigmoid'}
                    tpoints{ii+1,jj+1,kk+1} = max(0,min(1,4 - log(1./cumsum(phist) - 1)/8));
                case 'rayleigh'
                    tpoints{ii+1,jj+1,kk+1} = max(0,min(1,sqrt(-0.3*log(1-cumsum(phist)))));
                otherwise
                    tpoints{ii+1,jj+1,kk+1} = cumsum(phist); % why bother interpolating twice??
                    % % For anything other than uniform, tpoints needs to be transformed before the interpolation later
                    
                    % %             [x,n] = cumfreqplot(tileim(:),'-b',1,1);
                    % %             tpoints{ii,jj,kk} = interp1q(n',x',fracs);
                    % %             if ii==6 && jj==5
                    % %                 keyboard
                    % %             end
            end
        end
    end
end

% from here, need to work out the scaling for each tile, and then how to
% interpolate between tile centres

tpoints(1,:,:) = tpoints(2,:,:);
tpoints(:,1,:) = tpoints(:,2,:);
tpoints(:,:,1) = tpoints(:,:,2);

tpoints(end,:,:) = tpoints(end-1,:,:);
tpoints(:,end,:) = tpoints(:,end-1,:);
tpoints(:,:,end) = tpoints(:,:,end-1);

% for every tile, calculate the 8 mappings around it.
% the tiles required change halfway across a tile, so maybe make new tiles
% for this?

for ii = 1:(ntiles(1)+1)
    for jj = 1:(ntiles(2)+1)
        for kk = 1:(ntiles(3)+1)
%             lastwarn('')
            lx = max(1,1+(ii-1.5)*tilesiz(1));
            ux = min(imsiz(1),(ii-0.5)*tilesiz(1));
            ly = max(1,1+(jj-1.5)*tilesiz(2));
            uy = min(imsiz(2),(jj-0.5)*tilesiz(2));
            lz = max(1,1+(kk-1.5)*tilesiz(3));
            uz = min(imsiz(3),(kk-0.5)*tilesiz(3));
            
            tileim = im(lx:ux,ly:uy,lz:uz);
            
%             if ~isempty(lastwarn)
%                 keyboard
%             end
            
            % this needs up to 8 mappings calculated for it, and then we
            % need to average these use a tri-linear weighting
            
            tsiz = size(tileim);
            % if we knew the sizes of each tile in advance then we could
            % sort out the x and y weights outside this loop..
            % could flag the parts that don't need calculating here as well
            if ii==1
                wx1 = zeros(tsiz);
                wx2 = ones(tsiz);
% %                 x1flag = 1;
% %                 x2flag = 0;
            elseif ii==(ntiles(1)+1)
                wx1 = ones(tsiz);
                wx2 = zeros(tsiz);
            else
                wx1 = repmat(linspace(1,0,tsiz(1))',[1,tsiz(2),tsiz(3)]);
                wx2 = 1 - wx1;
            end
            if jj==1
                wy1 = zeros(tsiz);
                wy2 = ones(tsiz);
            elseif jj==(ntiles(2)+1)
                wy1 = ones(tsiz);
                wy2 = zeros(tsiz);
            else
                wy1 = repmat(linspace(1,0,tsiz(2)),[tsiz(1),1,tsiz(3)]);
                wy2 = 1 - wy1;
            end
            if kk==1
                wz1 = zeros(tsiz);
                wz2 = ones(tsiz);
            elseif kk==(ntiles(3)+1)
                wz1 = ones(tsiz);
                wz2 = zeros(tsiz);
            else
                wz1 = repmat(permute(linspace(1,0,tsiz(3)),[1,3,2]),[tsiz(1),tsiz(2),1]);
                wz2 = 1 - wz1;
            end
            
            % now calculate the all the mappings for this tile
            
            % tpoints records the 'percentile' of each intensity bin.  For
            % uniform mapping this is already where the intensity should be
            % moved to, but for other mappings we need to interpolate where
            % each percentile should be on our chosen distribution.
            
            % So tpoints actually records the percentile and what we want
            % is the intensity value of that percentile.
            
% %             im111 = interp1q([0;x],[0;tpoints{ii,jj,kk}],tileim(:));
% %             im112 = interp1q([0;x],[0;tpoints{ii,jj,kk+1}],tileim(:));
% %             im121 = interp1q([0;x],[0;tpoints{ii,jj+1,kk}],tileim(:));
% %             im122 = interp1q([0;x],[0;tpoints{ii,jj+1,kk+1}],tileim(:));
% %             im211 = interp1q([0;x],[0;tpoints{ii+1,jj,kk}],tileim(:));
% %             im212 = interp1q([0;x],[0;tpoints{ii+1,jj,kk+1}],tileim(:));
% %             im221 = interp1q([0;x],[0;tpoints{ii+1,jj+1,kk}],tileim(:));
% %             im222 = interp1q([0;x],[0;tpoints{ii+1,jj+1,kk+1}],tileim(:));
            
            im111 = interp1([0;x],[0;tpoints{ii,jj,kk}],tileim(:));
            im112 = interp1([0;x],[0;tpoints{ii,jj,kk+1}],tileim(:));
            im121 = interp1([0;x],[0;tpoints{ii,jj+1,kk}],tileim(:));
            im122 = interp1([0;x],[0;tpoints{ii,jj+1,kk+1}],tileim(:));
            im211 = interp1([0;x],[0;tpoints{ii+1,jj,kk}],tileim(:));
            im212 = interp1([0;x],[0;tpoints{ii+1,jj,kk+1}],tileim(:));
            im221 = interp1([0;x],[0;tpoints{ii+1,jj+1,kk}],tileim(:));
            im222 = interp1([0;x],[0;tpoints{ii+1,jj+1,kk+1}],tileim(:));
            
% %             if nnz(isnan(im111+im112+im121+im122+im211+im212+im221+im222))>0
% %                 keyboard
% %             end
            
%             try
            J(lx:ux,ly:uy,lz:uz) = reshape(wx1(:).*(wy1(:).*(wz1(:).*im111 + wz2(:).*im112) + wy2(:).*(wz1(:).*im121 + wz2(:).*im122)) + ...
                wx2(:).*(wy1(:).*(wz1(:).*im211 + wz2(:).*im212) + wy2(:).*(wz1(:).*im221 + wz2(:).*im222)),...
                size(wx1));
%             catch
%                 keyboard
%             end
        end
    end
end