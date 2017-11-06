classdef ProcessFactory < handle
    % if feval will work on compiled code, then new processes can be
    % registered from a text file, calling the constructor using feval
    
    % eg
    % segObj = feval(this.ClassList{ii})
    % or 
    % segObj = feval([this.ClassList{ii} '.defaultSetup()']);
    
    % for now, just list all of the options
    
    properties
        MenuList
    end
    methods
        function this = ProcessFactory(menuh,callbackmeth)
            % create a list of all the methods
            this.MenuList{1} = uimenu(menuh,'Label','Threshold',...
                'callback',{callbackmeth,1});
            this.MenuList{2} = uimenu(menuh,'Label','Faint Nuclei',...
                'callback',{callbackmeth,2});
            this.MenuList{3} = uimenu(menuh,'Label','Faint Nuclei and Cell Mask',...
                'callback',{callbackmeth,3});
            
        end
        
        function segObj = getSegObj(this,ind)
            % this will be called by the containing class, most likely in
            % the callbackmeth method
            
            % This could also be done with events and listeners, in which
            % case the segObj could be passed as event data and the two
            % classes don't need to know anything about each other.
            
            switch ind
                case 1
                    segObj = ThresholdAZSeg();
                case 2
                    segObj = FaintNucAZSeg();
                case 3
                    segObj = TwoStageSeedAZSeg(FaintNucAZSeg,CellMaskAZSeg);
                otherwise
                    error('Unknown segmentation method, check that the menu list matches this one')
            end
            
        end
        
        
    end
end
