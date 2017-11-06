function labObj = autoLabelObj(L)

% automatically create the appropriate label object based on the type of
% raw data

if iscell(L) && numel(L)==1
    L = L{1}; % single channel constructors currently take raw data
end

if ~iscell(L)
    if size(L,3)>1
        labObj = cLabel3DnC(L);
    else
        labObj = cLabel2DnC(L);
    end
else
    if any(cellfun(@(x)size(x,3)>1,L))
        labObj = cLabel3DnC(L);
    else
        labObj = cLabel2DnC(L);
    end
end
