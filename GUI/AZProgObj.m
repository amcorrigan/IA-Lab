function progObj = AZProgObj(varargin)

persistent AZIcon

% only want to read this in once
if isempty(AZIcon)
    AZIcon = MultiIconStor('azlogo.gif');
end

progObj = AmcAutoImProg(AZIcon,varargin{:});

end