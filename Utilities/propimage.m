function propim = propimage(L,prop,zeroval)

% grayscale image which replaces the label value with the value of the
% property
if nargin<3 || isempty(zeroval)
    zeroval = NaN;
end

% propim = zeros(size(L));
% 
% for ii = 1:length(prop)
%     propim(L==ii) = prop(ii);
% end

if size(prop,1)==1 && size(prop,2)>1
    % it's a row vector, switch it round..
    prop = prop';
end

if size(prop,2)==1
    temp = [zeroval;prop(:)];
    propim = temp(L+1);
else
    propim = zeros([numel(L),size(prop,2)]);
    for ii = 1:size(prop,2)
        temp = [zeroval;prop(:,ii)];
        propim(:,ii) = temp(L(:)+1);
    end
    propim = reshape(propim,[size(L),size(prop,2)]);
end