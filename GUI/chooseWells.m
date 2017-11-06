function wellrowcol = chooseWells(IL,initSelection,parenth)

% find out what choices are available
wellidx = find(strcmpi('well',IL.ChoiceStruct.Labels),1,'first');

[r,c] = wellstr2rowcol(IL.ChoiceStruct.Choices{wellidx});
data = NaN*zeros(IL.PlateDimensions([2,1]));
data(amcSub2Ind(size(data),[r,c])) = 1;
            
if nargin<3 || isempty(parenth)
    parenth = gfigure();
end
set(parenth,'closerequestfcn',@figclosefun)

if nargin<2 || isempty(initSelection)
    initSelection = zeros(size(data));
elseif size(initSelection,2)==2 && size(data,2)~=2
    temp = initSelection;
    initSelection = zeros(size(data));
    initSelection(amcSub2Ind(size(data),temp)) = 1;
end

this.WellSelector = PlateShowSelect(data(:,:,[1,1,1]),parenth,initSelection);

uiwait(parenth);

% get the selected wells, then delete the figure
wellinds = this.WellSelector.Status==1;
wellrowcol = findn(wellinds);
delete(parenth)

end


function figclosefun(src,evt)

if isequal(get(src, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(src);
else
    % The GUI is no longer waiting, just close it
    delete(src);
end

end