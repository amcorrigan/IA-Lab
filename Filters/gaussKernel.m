function kk = gaussKernel(wid,relsiz)

% oversampling of 10x by default

if nargin<2 || isempty(relsiz)
    relsiz = 6;
end

siz = max(odd(relsiz.*wid,'up'),3);
n = (0.55:0.1:(siz+0.45))';
m = (1+siz)/2;
temp1 = exp(-((n-m).^2)/(2*wid^2));
kk = sum(reshape(temp1,[10,numel(temp1)/10]),1)';
kk = kk/sum(kk);
