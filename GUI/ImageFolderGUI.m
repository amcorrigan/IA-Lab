classdef ImageFolderGUI < ChoicesGUI
    properties
        MainVBox
        TreeUI
        TreeObj % can get this through the UI object, but store a reference here too..
        LoadButton
        
        ButtonBox
    end
    methods
        function this = ImageFolderGUI(treeObj,parenth)
            
            % set up the UI
            this.MainVBox = uix.VBox('parent',parenth);
            
            this.ButtonBox = uix.HBox('parent',this.MainVBox);
            
%             uix.Empty('parent',temphbox);
            this.LoadButton = uicontrol('style','pushbutton','parent',this.ButtonBox,...
                                        'String','Show Image','callback',@this.buttoncallback);
            
%             set(temphbox,'widths',[-1,100])
            
            panelh = uipanel('parent',this.MainVBox);
            set(this.MainVBox,'heights',[40, -1]);
            
            this.TreeUI = FileTreeUI(treeObj,panelh,'ImageIcon.png','FolderIcon.png');
            
            
        end
        
        function idx = getCurrentValues(this)
            idx = this.TreeUI.getSelectedFiles();
        end

        function idx = getPrevValues(this)
            idx = this.TreeUI.getPrevFiles();
        end
        
        function idx = getNextValues(this)
            idx = this.TreeUI.getNextFiles();
        end
        
        
        function buttoncallback(this,src,evt)
            % directly trigger the choiceUpdate event
            notify(this,'choiceUpdate')
        end
        
        function delete(this)
            % this should clean up the display
            delete(this.MainVBox)
            
        end
    end
end
