classdef FileTreeUI < handle
    properties
        FileTreeObj; % called a tree, but really is the node structure
        
        MTree;
        Container;
    end
    methods
        function this = FileTreeUI(treeObj, parenth, fileicon, foldericon)
            this.FileTreeObj = treeObj;
            
            if nargin>2 && ~isempty(fileicon)
                if ischar(fileicon)
%                     jFileImage = java.awt.Toolkit.getDefaultToolkit.createImage(fileicon);
                    jImage = im2java(imread(fileicon));
                else
                    jImage = im2java(fileicon);
                end
                for ii = 1:numel(treeObj.Nodes)
                    if get(treeObj.Nodes(ii),'Leaf')
                        treeObj.Nodes(ii).setIcon(jImage)
                    end
                end
            end
            
            if nargin>2 && ~isempty(foldericon)
                if ischar(foldericon)
%                     jFileImage = java.awt.Toolkit.getDefaultToolkit.createImage(fileicon);
                    jImage = im2java(imread(foldericon));
                else
                    jImage = im2java(foldericon);
                end
                for ii = 1:numel(treeObj.Nodes)
                    if ~get(treeObj.Nodes(ii),'Leaf')
                        treeObj.Nodes(ii).setIcon(jImage)
                    end
                end
            end
            
            [this.MTree, this.Container] = uitree('v0', 'Root',this.FileTreeObj.Nodes(1), ...
                'Parent',parenth...
                );% ,'SelectionChangeFcn',@this.selectCallback);
            set(this.Container,'parent',parenth,'units','normalized','position',[0,0,1,1])
            
            this.MTree.expand(this.FileTreeObj.Nodes(1))
            
            
        end
        
        function fileidx = getSelectedFiles(this,src,evt)
            sel = this.MTree.getSelectedNodes;
            
            if isempty(sel)
                fileidx = 0;
                return
            end
            % sel is a java array of nodes, go through each of them in turn
            fileidx = zeros(sel.length,1);
            for ii = 1:sel.length
                % need to find out where this node is
                % this might be easier to store in the userobject property
                ind = sel(ii).getUserObject();
                
                if ~isempty(ind)
                    fileidx(ii) = ind;
%                 else
%                     fileidx(ii) = this.getNextFiles();
                end
            end
        end
        
        
        function o_fileIndex = getPrevFiles(this,src,evt)
            sel = this.MTree.getSelectedNodes;
            
            prevNode = sel;
            for i = 1:sel.length
                aNode = sel(i).getPreviousNode();
                
                if isempty(aNode)
                    prevNode(i) = sel(i);
                else
                    prevNode(i) = aNode(i);
                end;
                
                while prevNode(i).isLeaf ~= true
                    aNode = prevNode(i).getPreviousNode();

                    if isempty(aNode)
                        prevNode(i) = prevNode(i).getFirstLeaf();
                        break;
                    end;
                    
                    prevNode(i) = aNode;
                end;
            end

            %-- Find the node wih the smallest index
            for ii = 1:sel.length
                o_fileIndex(ii) = prevNode(ii).getUserObject();
            end
            
            %-- Get the smallest index
            [o_fileIndex, nodeIndex] = min(o_fileIndex);
            
            this.MTree.setSelectedNode(prevNode(nodeIndex));
        end
        
        function o_fileIndex = getNextFiles(this,src,evt)
            sel = this.MTree.getSelectedNodes;
            
            nextNode = sel;
            for i = 1:sel.length
                aNode = sel(i).getNextNode();
                
                if isempty(aNode)
                    disp('Warning!--------------');
                    nextNode(i) = sel(i);
                else
                    nextNode(i) = aNode(i);
                end;
                
                while nextNode(i).isLeaf ~= true
                    aNode = nextNode(i).getNextNode();

                    if isempty(aNode)
                        nextNode(i) = nextNode(i).getLastLeaf();
                        break;
                    end;
                    
                    nextNode(i) = aNode;
                end;
            end

            %-- Find the node wih the largest index
            for ii = 1:sel.length
                o_fileIndex(ii) = nextNode(ii).getUserObject();
            end
            
            %-- Get the largest index
            [o_fileIndex, nodeIndex] = max(o_fileIndex);
            
            this.MTree.setSelectedNode(nextNode(nodeIndex));
        end
        
    end
end