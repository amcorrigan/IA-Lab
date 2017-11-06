classdef ChoicesGUI < handle
    % interface for defining a ChoicesGUI object, which displays the
    % options for selecting an image, and passes the information to the
    % image loader when requested
    
    % at some point soon, ButtonBox will be either a method or property
    % that all ChoicesGUI classes should have, for adding extra buttons (eg
    % QC) to the GUI.
    
    events
      choiceUpdate
    end
    methods
        values = getCurrentValues(this);
        
        % other methods to add might include directly setting the GUI to a
        % chosen selection
    end
end