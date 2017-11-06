function fileNames = cmddir(patt,fol,includePath)

if nargin<3 || isempty(includePath)
    includePath = false;
end

if nargin>1 && ~isempty(fol)
    patt = fullfile(fol,patt);
end

patt = regexprep(patt,'/','\\');

if ispc
    cmdArray = sprintf('dir \"%s" /b /a-d', patt);
    [~, cmdOutput] = dos(cmdArray);

    % fix for a warning message that comes up when dir is called
    % from a network location
    newlineInds = strfind(cmdOutput,sprintf('\n'));

    ind1 = [1;newlineInds(1:end-1)'+1];
    ind2 = newlineInds'-1;
    fileNames = arrayfun(@(x,y) cmdOutput(x:y),ind1,ind2,'uni',false);

    if any(strcmpi(fileNames,'UNC paths are not supported.  Defaulting to Windows directory.'))
        % the first three rows need removing
        fileNames = fileNames(4:end);
    end

    if any(strcmpi(fileNames,'File Not Found'))
        fileNames = {};
        return;
    end

else
%                 error('Not currently implemented for non-Windows')
    temp = dir(patt);
    fileNames = {temp.name}';
end

if includePath
    % only the filename is returned, not the parent folder or the path to
    % the file
    [a,b,c] = fileparts(patt);
    
    if ~isempty(a)
        fileNames = cellfun(@(x)fullfile(a,x),fileNames,'uni',false);
    end
end

