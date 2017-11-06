% Combine two labels, using the specified function
%> @file LabelCombineAZSeg.m
%> @brief Combine two labels, using the specified function
%> The default use for this will be to remove nuclei from
%> cytoplasmic labels, ie an AND NOT operation but it can be generalised to OR, intersect, etc
%
%> To begin with don't need to check if it's the same label
%> number in each, although a min might work as AND?
    
classdef LabelCombineAZSeg < AZSeg
    % Combine two labels, using the specified function
    % To begin with the default use for this will be to remove nuclei from
    % cytoplasmic labels, but it can be generalised to OR, intersect, etc
    %
    % For this original use, we don't need to check if it's the same label
    % number in each, although a min might work as AND?
    
    
    properties
        Type = 'AndNot';
    end
    methods
        % ======================================================================
		%> @brief Class constructor
		%>
		%> Return the segmentation object with initial values for tuneable parameters
		%>
		%> @param type The operation to be performed (default 'andnot')
		%> @return instance of the LabelCombineAZSeg class.
		% ======================================================================
        function this = LabelCombineAZSeg(type)
            this@AZSeg({},{},'Label Combine',0,2,1);
            if nargin>0 && ~isempty(type)
                this.Type = type;
            end
        end
        
        % ======================================================================
		%> @brief Run the label combining operation
		%>
		%> 
		%> @param this instance of the LabelCombineAZSeg class
		%> @param ~ no image data required for this class
		%> @param labdata cell array of label matrices on which to perform the operation
		%>
		%> @return Lout the output label matrix
		% ======================================================================
        function Lout = process(this,~,labdata)
            % no image data, but interface requires this as the second
            % input
            if ischar(this.Type)
                switch this.Type
                    otherwise
                        Lout = labdata{1};
                        Lout(labdata{2}>0) = 0;
                end
            elseif isa(this.Type,'function_handle')
                Lout = this.Type(labdata{1},labdata{2});
            end
        end
    end
end