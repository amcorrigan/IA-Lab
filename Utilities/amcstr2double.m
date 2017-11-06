function X = amcstr2double(str)

% wrap str2double in a checker to ensure that if no inputs are provided, an
% empty result is returned rather than throwing an error.
% This can now be used in a ternary operation

if nargin==0
    X = [];
else
    X = str2double(str);
end
