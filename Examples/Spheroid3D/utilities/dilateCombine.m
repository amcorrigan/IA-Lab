function fim = dilateCombine(im,nhoods,reps,maxfactor)

% combine the image with a dilated version of itself

if nargin<4 || isempty(maxfactor)
    maxfactor = 1;
end

if nargin<3 || isempty(reps)
    reps = 1;
end

if ~iscell(nhoods)
    nhoods = {nhoods};
end

tempim = im;
fim = im;

for ii = 1:reps
    tempim2 = tempim;
    for jj = 1:numel(nhoods)
        tempim2 = imdilate(tempim2,nhoods{jj});
    end
    
    if ~isnan(maxfactor)
        tempim = max(tempim,maxfactor*tempim2);
        fim = max(fim,maxfactor*tempim);
    else
        tempim = tempim2;
        fim = fim + tempim;
    end
    
    % various options for the combination
    % - add
    % - max
    % - scale and then max
    
    
end