classdef GenEvtData < event.EventData
    % general event data, allowing any data to be passed
    properties (Access = public)
        % Event data
        data
    end

    methods
        function obj = GenEvtData(data)
            obj.data = data;
        end
    end
end