classdef AZMeasure < handle
    % Interface for measurement classes
    % The fundamental method call will be:
    % stats = AZMeasure.measure(labeldata,imdata)
    %
    % There may be user supplied parameters that need to be adjusted, for
    % example in binning into a number of groups, or applying a cutoff.
    
    properties
        Prefix = '' % this is a user supplied prefix for each of the fields
                    % allowing multiple runs of the same measurement class
                    % to be distinguished
        
        OutputType = 'SingleCell';
        NumInputLabels
        NumInputImages
    end
    methods
        function this = AZMeasure(propPrefix)
            if nargin>0 && ~isempty(propPrefix)
                this.Prefix = propPrefix;
            end
        end
        [stats,varargout] = measure(this,L,imdata);
    end
end