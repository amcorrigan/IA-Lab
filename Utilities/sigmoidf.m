function y = sigmoidf(x,sc,offset)

if nargin<3 || isempty(offset)
    offset = 0;
end
if nargin<2 || isempty(sc)
    sc = 1;
end

y = 1./(1+exp(-(x-offset)/sc));