function az_deployThis_3DSegment(i_version, i_saveDir, i_mainFunctionName)

% 
%     if nargin <= 2
%         i_mainFunctionName = 'playGUI.m';
%     end;
%     
%     if nargin <= 1
%         i_saveDir = '\\UK-Image-01\IAGroup\SB\2016\Yoko\Source Code';
%     end;
    
%%___________________________________________________________
%%  Current Date
    t = datetime;
    t.Format = 'yyyy-MM-dd';
    dateString = datestr(t, 'yyyy-mm-dd');
%%___________________________________________________________
%%
    saveDir = sprintf('%s\\%s Release %s', i_saveDir, dateString, i_version);
   
    flag = exist(saveDir, 'dir');
    if flag ~= 7
        status = mkdir(saveDir);
        
        if status  == 0
            msgbox('You are not allowed to create a folder in this directory, please contact system administrator for help.', 'Error', 'error');
            return;
        end;
    end;
    
%%___________________________________________________________
%%
    fList = matlab.codetools.requiredFilesAndProducts(i_mainFunctionName);

    for i = 1:length(fList)
        sourceFile = fList{i};
        
        subString = strsplit(sourceFile,'\');
        fileName = subString{end};
    
        aString = sprintf('dir /s /b /o:gn "%s"', fileName);
        
        [flag, fullFileName] = dos(aString);
        
        %-- file exist
        if flag ~= 0 && strcmp(fullFileName, 'File Not Found')==1
            destFile = sprintf('%s\\%s', saveDir, subString{end});
            
            status = copyfile(sourceFile, destFile);

            if status == false
                disp('Yinhai: Error deploying!');
                return;
            end
        end;
    end;
%%___________________________________________________________
%%
    winopen(saveDir);
end