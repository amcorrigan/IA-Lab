function [x,y,z] = amcMakeGrid(im)

% makegrid (because it uses ndgrid) can be very memory intensive (the
% problem seems to be the permute command (line 48 of ndgrid)

% Do something about this
if numel(im)>3
    ss = size(im);
else
    ss = im;
end

if numel(ss)==1
    ss = ss*ones(1,nargout);
end

if numel(ss)==2 && nargout>2
    ss = [ss,1];
end

switch length(ss)
    case 2
%         [x,y] = ndgrid(1:ss(1),1:ss(2));
        x = repmat((1:ss(1))',[1 ss(2)]);
        y = repmat((1:ss(2)),[ss(1) 1]);
        z = ones(size(x));
    case 3
%         [x,y,z] = ndgrid(1:ss(1),1:ss(2),1:ss(3));
        x = repmat((1:ss(1))',[1 ss(2) ss(3)]);
        y = repmat((1:ss(2)),[ss(1) 1 ss(3)]);
        z = repmat(permute((1:ss(3)),[1 3 2]),[ss(1) ss(2) 1]);
end