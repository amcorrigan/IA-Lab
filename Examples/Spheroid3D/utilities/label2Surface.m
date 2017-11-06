function fv = label2Surface(L,pixsize)

if nargin<2 || isempty(pixsize)
    pixsize = [1,1,1];
end

for ii = 1:max(L(:))
    fv(ii) = surfcapsstruct([],[],[],L==ii,pixsize);
end