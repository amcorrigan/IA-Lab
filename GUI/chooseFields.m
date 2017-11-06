function fvalues = chooseFields(IL,initSelection,parenth)

% choose selected z planes for modifying the import file.
% This could be completely generalised, nothing field or z specific here
% apart from the choice of label

fidx = find(strcmpi('field',IL.ChoiceStruct.Labels),1,'first');
origfvalues = IL.ChoiceStruct.Choices{fidx};

if nargin<3 || isempty(parenth)
    parenth = gfigure();
end
set(parenth,'closerequestfcn',@figclosefun)

vbox = uix.VBox('parent',parenth,'padding',20);
uicontrol('parent',vbox,'style','text','String','Select planes:');
lbox = uicontrol('parent',vbox,'style','listbox','Max',100,'min',0,...
    'string',arrayfun(@num2str,origfvalues,'uni',false),'value',[]);

if nargin>1 && ~isempty(initSelection)
    selinds = any(bsxfun(@eq,origfvalues(:),initSelection(:)'),2);
    set(lbox,'value',origfvalues(selinds))
end

temphbox = uix.HBox('parent',vbox);
uicontrol('parent',temphbox,'style','pushbutton','String','Select all',...
    'callback',{@selectallcallback,lbox});
uix.Empty('parent',temphbox);
uicontrol('parent',temphbox,'style','pushbutton','String','Finish',...
    'callback',@(src,evt)close(parenth));
set(temphbox,'widths',[-1,-2,-2])

set(vbox,'heights',[-1,-5,-1]);

uiwait(parenth);

% get the selected wells, then delete the figure
finds = get(lbox,'value');

fvalues = origfvalues(finds);

delete(parenth)

end

function selectallcallback(src,evt,lbox)

numvals = numel(get(lbox,'String')); % need to check this works even in the event of one plane

set(lbox,'value',1:numvals)

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