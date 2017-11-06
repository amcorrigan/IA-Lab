function o_counter = az_countNoLines(i_dir)

%%____________________________________________________________
%%
    if nargin == 0
        i_dir = 'C:\GIT_AZ\spheroid3d';
    end
    
%%____________________________________________________________
%%
    aString = sprintf('dir /s/b/o:gn %s\\*.m', i_dir);
    
    [~, theList] = dos(aString);
    
    theList = strsplit(theList, '\n');
%%____________________________________________________________
%%
    
    o_counter = 0;
    for i = 1:length(theList)
        if isempty(theList{i}) == 0
            fid = fopen(theList{i},'r');
            fseek(fid, 0, 'eof');
            chunksize = ftell(fid);
            fseek(fid, 0, 'bof');
            ch = fread(fid, chunksize, '*uchar');
            o_counter = o_counter + sum(ch == sprintf('\n')); % number of lines 
            fclose(fid);
        end;
    end

    aString = sprintf('Number lines of code: %d', o_counter);
    disp(aString);

end

    