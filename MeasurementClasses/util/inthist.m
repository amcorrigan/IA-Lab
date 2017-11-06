function varargout = inthist(data,doplot)

if nargin<2 || isempty(doplot)
    doplot = 0; % don't plot by default
end

if nargout==0
    doplot = 1;
end

x = min(1,min(data)):max(data);
n = hist(data,x);

if doplot
    bar(x,n,'hist');
end

if nargout>0
    varargout{1} = n;
    if nargout>1
        varargout{2} = x;
    end
end


