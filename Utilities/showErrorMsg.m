function showErrorMsg(MEs,fid)

% allow multiple errors to be passed together as a cell array

if nargin<2 || isempty(fid)
    fid = 1; % 1 is hopefully the screen
end

if ~iscell(MEs)
    MEs = {MEs};
end

for ii = 1:numel(MEs)
    if ~isempty(MEs{ii})
        fprintf( '---------------\n' );
        if numel(MEs)>1
            fprintf(fid, 'Error number %d\n%s\n', ...
                     ii, getReport(MEs{ii}) );
        else
            fprintf(fid, 'Error\n%s\n', ...
                     getReport(MEs{ii}) );
        end
    end
end