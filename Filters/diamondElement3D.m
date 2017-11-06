function diel = diamondElement3D(wid,siz)

% specifying the size separately is useful for if we want to subtract this
% structure element from a larger one.
if nargin<1 || isempty(wid)
    wid = 1;
end
if nargin<2
    siz = wid;
end

[rr,cc,pp] = meshgrid(-siz:siz);
diel = (abs(rr) + abs(cc) + abs(pp)) <= wid;


