function ia = nucleiExample()

% the function nuclearPropertiesWorkflow.m returns a HCWorkFlow object.
% the function creates each of the analysis steps and adds them to the
% workflow.
wk = nuclearPropertiesWorkflow();

% The GUI is then invoked, and the workflow attached to the GUI object
ia = HCExplorer().addWorkflow(wk);


% optionally quit MATLAB upon exit - uncomment the code below
% % waitfor(ia.Figure1)
% % quit()

end