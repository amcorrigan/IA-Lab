function outim = amcFillNaNs(im,blurScale,maxIts,initScale,epsilon)

% fill in NaNs by iteratively blurring from the edges

if nargin<2 || isempty(blurScale)
    blurScale = max(1,0.01*min(size(im,1),size(im,2)));
end

if nargin<3 || isempty(maxIts)
    maxIts = 40;
end

if nargin<4 || isempty(initScale)
    initScale = 5*blurScale;
end

if nargin<5 || isempty(epsilon)
    epsilon = 2e-2;
end

nanreg = isnan(im);

fim = gaussBlurNaNs(im,initScale,nanreg);
while nnz(isnan(fim))>0
    fim = gaussBlurNaNs(fim,initScale);
end

outim = im;
outim(nanreg) = fim(nanreg);

for ii = 1:maxIts
    fim = gaussFiltND(outim,blurScale*[1,1]);
    if max(abs(fim(nanreg)-outim(nanreg))./outim(nanreg))<epsilon
        outim(nanreg) = fim(nanreg);
        break;
    else
        outim(nanreg) = fim(nanreg);
    end
end

end

function fim = gaussBlurNaNs(im,lscale,bw)

if nargin<3 || isempty(bw)
    bw = isnan(im);
end

im(bw) = 0;

num = gaussFiltND(im,lscale*[1,1],0);
denom = gaussFiltND(~bw,lscale*[1,1],0);

fim = num./denom;

end