function y = amcStd(x,dim,flag)

% AMC version of std which ignores NaNs AND INFINITIES by default

if nargin<3 || isempty(flag)
    flag = 0; % flag==0 means use n-1 rather than n
end

% ignore NaNs and Infs
if nargin<2 || isempty(dim)
    dim = find(size(x)>1,1,'first');
    if isempty(dim)
        dim = 1;
    end
end

% %     % reshape so that dim is the first dimension
% %     inds = 1:length(size(x));
% %     inds(inds==dim) = [];
% %     inds = [dim inds];
% % 
% %     [empt,invinds] = sort(inds,'ascend');
% % 
% %     x = permute(x,inds);
% %     newsiz = size(x);
% % 
% %     for ii = 1:length(x(1,:))
% %         y(ii) = std(x(~isnan(x(:,ii)) & ~isinf(x(:,ii)),ii),flag);
% %     end
% % 
% %     y = permute(reshape(y,[1 newsiz(2:end)]),invinds);
    inds = isfinite(x);
    denom = sum(inds,dim);
    d2 = denom;
    if flag==0
        d2 = d2-1;
    end
    
    
    x(~inds) = 0;
    num = sum(x,dim);
    num2 = sum(x.^2,dim);

    y = sqrt((num2 - (num.^2)./denom)./d2);

% % else

if isempty(y)
    y = NaN;
end
% % end

