function bordxy = label2outline(L,skip,interpfact)

% Currently the interpolation means that there is a bit of a discontinuity
% at the join, this needs tidying up by extending the range of the
% interpolation input

% no real logic behind choosing these factors, just whatever looks nice and
% retains the detail of the label matrix
if nargin<2 || isempty(skip)
    skip = 6;
end
if nargin<3 || isempty(interpfact)
    interpfact = 2*skip;
end

stats = labelBorder2D(L);

bordxy = cell(numel(stats),1);

for ii = 1:numel(stats)
    borderskip = stats(ii).border([(1:skip:end-1),1],:); % make sure circular
    if ~isnan(interpfact)
        inds = (-1:(size(borderskip,1)+2))';
        actinds = mod(inds-1,size(borderskip,1))+1;
        bordxy{ii} = interp1(inds,borderskip(actinds,:),...
            linspace(1,size(borderskip,1),interpfact*size(borderskip,1))','spline');
    else
        bordxy{ii} = borderskip;
    end
end

end

function stats = labelBorder2D(L)

% return a structure which contains border information for the different
% regions in the label matrix L.
% Absolute means that the centroid isn't subtracted off

% this approach is predicated on having 2D separation.  This means that 3D
% overlapping objects or objects without a boundary of zeros separating
% them will cause problems

bw = L>0;

[B,L2] = bwboundaries(bw,8,'noholes');

if max(L2(:))==max(L(:))

    cumL = borderLength(B);

    stats = regionprops(L2,L,'MeanIntensity');
    for ii = 1:numel(stats)
    %     stats(ii).rawborder = B{ii};
        stats(ii).cumL = cumL{ii};
        stats(ii).border = B{ii};
    end

    % rearrange based on the mean region intensity, which should always match
    % exactly with the region in the original matrix
    ix = [stats.MeanIntensity];

    % stats = stats(ix);
    stats(ix) = stats;
    
    stats = rmfield(stats,'MeanIntensity');
else
    % no clear 2D boundary, so have to do one label at a time
    % This also carries the assumption that each region is contiguous.
    
    for ii = 1:max(L(:))
        
        if nnz(L==ii)>0
            B = bwboundaries(L==ii,8,'noholes');
            if ~iscell(B)
                B = {B}; % easier to do this way round..
            end

            cumL = borderLength(B);
            
            tstats.cumL = cumL{1};
            tstats.border = B{1};


            stats(ii) = tstats;
        else
            tstats.cumL = NaN;
            tstats.border = NaN;
            
            stats(ii) = tstats;
        end
    end
    
end

end

function cumL = borderLength(B)

% return the cumulative length along the border pixels contained in B

if ~iscell(B)
    B = {B};
end

cumL = cell(size(B));
for ii = 1:numel(B)
    dd = diff(B{ii},1,1);
    
    sL = sqrt(sum(dd.^2,2));% simple addition may be quicker than calling sum
                            % but MIGHT not alway be in 2D..
    
    cumL{ii} = [0;cumsum(sL)];
end


end
