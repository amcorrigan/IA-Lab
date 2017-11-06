function inds = amcInd2Sub(siz,idx)

% AMC version of ind2sub
% 
% version of ind2sub which doesn't require the dimensionality to be
% specified explicitly in the number of outputs
% basically convert find indices into findn indices

inds = zeros(numel(idx),numel(siz));

ndim = length(siz);
k = [1 cumprod(siz(1:end-1))];
idx = idx(:);
for ii = ndim:-1:1
    inds(:,ii) = ceil(idx/(k(ii)));
    idx = idx - k(ii)*(inds(:,ii)-1);
end
