function output = ternaryfcn(condfcn,truefcn,falsefcn,varargin)

% MATLAB version of ternary operator, for inlining into functions like
% cellfun or arrayfun without having to create extra functions.

% functions are used here to prevent having to evaluate everything

if isa(condfcn,'function_handle')
    TF = condfcn(varargin{:});
else
    TF = condfcn;
end

if TF
    if isa(truefcn,'function_handle')
        output = truefcn(varargin{:});
    else
        output = truefcn;
    end
else
    if isa(falsefcn,'function_handle')
        output = falsefcn(varargin{:});
    else
        output = falsefcn;
    end
end