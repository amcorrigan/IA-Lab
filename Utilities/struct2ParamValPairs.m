function args = struct2ParamValPairs(s)

% convert the structure s into parameter-value pairs for function inputs

temp = struct2cell(s);
fnames = fieldnames(s);
args = [fnames';temp'];
args = args(:);