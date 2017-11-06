function o_folderNames = az_getSubFolders(i_aPath)

%%___________________________________________
%%  
    cmdArray = sprintf('dir \"%s\" /ad /b /on', i_aPath);
    [status, folderName] = dos(cmdArray);

    folderNames = strsplit(folderName, '\n');
    
    o_folderNames = folderNames(~cellfun('isempty',folderNames));
            

end