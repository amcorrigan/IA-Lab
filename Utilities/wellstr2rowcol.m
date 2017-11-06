function [r,c] = wellstr2rowcol(wellstr)

% convert the well label (eg 'F05') to row and column indices
%
% Look out for a decimal point in the string, this means that the plate is
% a 1536 well plate, and needs to be treated differently.
%

% start with the regular plates
if ~iscell(wellstr)
    wellstr = {wellstr};
end
s = cell2mat(regexp(wellstr,'(?<row>[A-Z])(?<col>\d{1,2})','names'));
r = double(upper([s.row]))'-64;
c = arrayfun(@(x)str2double(x.col),s);