function imObj = createImObj(data,colours)

if ~iscell(data)
    data = {data};
end

for ii = 1:numel(data)
    % need to convert to uint16 for speed of display and contrast
    % adjustment
    if ~isa(data{ii},'uint16')
        data{ii} = im2uint16(mat2gray(data{ii}));
    end
end
is3d = any(cellfun(@(x)size(x,3)>1,data));

if nargin<2 || isempty(colours)
    colours = {[0,0,1];[0,1,0];[1,0,0];[1,1,1];[1,1,0];[0,1,1];[1,0,1]};
end

nativecolour = colours(mod((1:numel(data))'-1,numel(colours))+1);

if is3d
    imObj = cImage3DnCNoFile(data,nativecolour,1:numel(data),[],'Image');
else
    imObj = cImage2DnC([],[],nativecolour,1:numel(data),[],'Image',data);
end