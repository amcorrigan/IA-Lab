classdef FileTree < handle
    properties
        Tree
        Nodes
        FileNames = {};
        NodeIdx
% %         FileIdx
    end
    methods
        function this = FileTree(fol,patt,maxdepth)
            % build the file tree and store it in this class
            [~,folname] = fileparts(fol);
            
            this.Nodes = uitreenode('v0',folname,folname,[],false);
            
            
            % add file and folder nodes to the tree until we get to the
            % specified depth
            currdepth = 0;
            nodeCount = 1;
            fileCount = 0;
            
            newfolders = {fol};
            newIdx = 1; % start at the root node
            while currdepth<=maxdepth
                currfol = newfolders;
                currIdx = newIdx;
                
                newfolders = {};
                newIdx = [];
                for ii = 1:numel(currfol)
                    [newfiles,newfolstruct] = FileTree.recurseNextLevel(currfol{ii},patt);
                    
                    
                    for jj = 1:numel(newfiles)
                        nodeCount = nodeCount + 1;
                        fileCount = fileCount + 1;
                        
                        % add the new files as leaf nodes
                        this.Nodes(nodeCount) = uitreenode('v0',newfiles(jj).name,...
                            newfiles(jj).name,[],true);
                        this.Nodes(currIdx(ii)).add(this.Nodes(nodeCount));
                        
                        this.Nodes(nodeCount).setUserObject(fileCount);
                        % record the full file name
                        this.FileNames{fileCount,1} = newfiles(jj).fullpath;
                        
                        % link the node to the index of the filename
                        this.NodeIdx(fileCount) = nodeCount;
                    end
                    
                    
                    % if we're not at max depth, add the new folders as
                    % nodes
                    newfolders = [newfolders;{newfolstruct.fullpath}'];
                    for jj = 1:numel(newfolstruct)
                        nodeCount = nodeCount + 1;
                        
                        this.Nodes(nodeCount) = uitreenode('v0',newfolstruct(jj).name,...
                            newfolstruct(jj).name,[],false);
                        newIdx = [newIdx;nodeCount];
                        
                        this.Nodes(currIdx(ii)).add(this.Nodes(nodeCount));
                    end
                end
                
                
                currdepth = currdepth + 1;
            end
            
% %             this.Tree = uitree();
        end
    end
    methods (Static)
        function [files,folders] = recurseNextLevel(fol,patt)

            if iscell(patt)
                files = [];
                for ii = 1:numel(patt)
                    newFiles = amcFullDir(patt{ii},false,fol);
                    
                    if ~isempty(newFiles)
                        files = [files;newFiles];
                    end
                end
                
                % make sure that duplicate files (which match more than one
                % pattern) are removed
                [~,ix] = unique({files.fullpath}');
                files = files(ix);
                
            else
                files = amcFullDir(patt,false,fol);
            end

            folders = amcFullDir('*',true,fol);
        end
    end
end