function fullname = syspath(localname)

% platform independent method of getting the full path from a local name

if ispc
    % Windows
    fullname = char(System.IO.Path.GetFullPath(localname));
elseif isunix
    % UNIX
    warning('UNIX functionality not fully tested for this function')
    if strcmpi(localname(1),'/')
        % already a fullpath
        fullname = localname;
        
    else
        fullname = fullfile(cd,localname);
    end
else
    % Mac
    tempid = fopen(localname);
    fullname = fopen(tempid);
end