function flag = mlfSelect(inputFilename,outputFilename,rowcol,zslices,fields)

flag = 0;
fid = fopen(inputFilename);
if fid<0
    flag = 1;
    return
end
try
    s = textscan(fid,'%s','Delimiter','\n');
    s = s{1};
catch ME
    fclose(fid);
    rethrow(ME)
end
fclose(fid);

keep = false(size(s));
keep([1,2,end]) = true;


% need to treat the channels and zslices separately, then combine with an
% AND operation
if nargin>2 && ~isempty(rowcol)
    wellkeep = false(size(s));
    for ii = 1:size(rowcol,1)
        rowpatt = sprintf('bts:Row="%d"',rowcol(ii,1));
        colpatt = sprintf('bts:Column="%d"',rowcol(ii,2));
        
        try
        matches = ~cellfun(@isempty,regexp(s,rowpatt)) & ~cellfun(@isempty,regexp(s,colpatt));
        catch ME
            keyboard
        end
%         matches = cellfun(@(x)~isempty(regexp(x,rowpatt)) & ~isempty(regexp(x,colpatt)),s);
        wellkeep(matches) = true;
    end
else
    wellkeep = true(size(s));
end

if nargin>3 && ~isempty(zslices)
    zkeep = false(size(s));
    for ii = 1:numel(zslices)
        zpatt = sprintf('bts:ZIndex="%d"',zslices(ii));
        matches = ~cellfun(@isempty,regexp(s,zpatt));
        zkeep(matches) = true;
    end
else
    zkeep = true(size(s));
end

if nargin>4 && ~isempty(fields)
    fkeep = false(size(s));
    for ii = 1:numel(fields)
        fpatt = sprintf('bts:FieldIndex="%d"',fields(ii));
        matches = ~cellfun(@isempty,regexp(s,fpatt));
        fkeep(matches) = true;
    end
else
    fkeep = true(size(s));
end

sk = s(keep | (wellkeep & zkeep & fkeep));

fid = fopen(outputFilename,'w+');

if fid<0
    flag = 2;
    return
end
fwrite(fid,sprintf('%s\n',sk{:}));
fclose(fid);