function out = odd(x,direction)

if nargin<2
	direction = 'up';
end
if ~ischar(direction)
	if direction>0
		direction = 'up';
	else
		direction = 'down';
	end
end

switch direction
	case 'up'
		out = ceil((x + 1)/2)*2 - 1;
	case 'down'
		out = floor((x + 1)/2)*2 - 1;
end