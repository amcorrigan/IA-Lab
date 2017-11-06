function outdata = amcSmooth(indata,ww)

% essentially emulate the matlab smooth function; average over a window of
% width ww (must be odd).

if nargin<2 || isempty(ww)
    ww = 3;
end
ww = odd(ww,'up');
outdata = zeros(size(indata));

for ii = 1:length(indata(:))
    avinds = (max(1,ii-(ww-1)/2)):(min(length(indata(:)),ii+(ww-1)/2));
    tempdata = indata(avinds);
    outdata(ii) = mean(tempdata(~isnan(tempdata)));
end
    