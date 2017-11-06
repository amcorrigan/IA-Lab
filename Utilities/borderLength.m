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


