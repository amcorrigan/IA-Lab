function figh = gfigure(varargin)

% create a GUI-style figure, with no toolbar or standard menu bar
if nargin==1
    if isa(varargin{1},'matlab.ui.Figure')
        figh = varargin{1};
    elseif ischar(varargin{1})
        figh = figure('Name',varargin{1});
    else
        error('Unknown input option')
    end
else
    figh = figure(varargin{:});
end

set(figh,'NumberTitle', 'off', ...
    'Toolbar', 'none', ...
    'MenuBar', 'none' );

