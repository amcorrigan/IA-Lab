function o_finalFolderName = az_getDeepestChildFolderName(i_aPath)
%  Find the deepest child dir
%  Two methods have been tried here, i) dir, ii)genpath (extremely slow
%     when folder is \\'

%%___________________________________________
%%  
    try
        cmdArray = sprintf('dir \"%s\" /s /b /o:n /ad', i_aPath);

        [status, folderName] = dos(cmdArray);

        if status == 0 & ~isempty(folderName)
            folderName = strsplit(folderName, '\n');
            
            if isempty(folderName) || ...
               (length(folderName) == 1 && isempty(folderName{1}))
                temp = strsplit(i_aPath, '\');
                folderName = temp(end);
            end;
        elseif status == 0 & isempty(folderName)
            folderName{1} = i_aPath;
        else
            folderNameArray = genpath(i_aPath);
            folderNameArray = cat(2, ';', folderNameArray);
            k = strfind(folderNameArray, ';');

            folderName = {};
            for i = length(k):-1:2
                folderName{i-1} = folderNameArray(k(i-1)+1:k(i)-1);
            end;
        end

        [~, index] = max(cellfun(@length, folderName));

        o_finalFolderName = folderName{index};
    catch
        o_finalFolderName = [];
    end
end