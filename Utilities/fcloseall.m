function varargout = fcloseall()

fids = fopen('all');
flag = arrayfun(@fclose,fids);

if nargout>0
    varargout{1} = flag;
    if nargout>1
        varargout{2} = fids;
    end
end