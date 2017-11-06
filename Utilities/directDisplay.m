function varargout = directDisplay(imdata,cols)

% create an image object for displaying the data

if ~iscell(imdata)
    imdata = {imdata};
end

for ii = 1:numel(imdata)
    if ~isa(imdata{ii},'uint16')
        imdata{ii} = uint16(rangeNormalise(imdata{ii})); % will this be quite slow?
    end
end

if nargin<2 || isempty(cols)
    cols = num2cell([1,0,0;0,1,0;0,0,1;1,1,1;1,1,0;1,0,1;0,1,1],2);
end
if ~iscell(cols)
    cols = num2cell(cols,2);
end
if numel(cols)<numel(imdata)
    cols = cols(mod(0:(numel(imdata)-1),numel(cols))+1);
end


imObj = cImage3DnCNoFile(imdata,cols,[],[],'Direct image');

dispObj = imObj.showImage;

if nargout>0
    varargout{1} = dispObj;
    if nargout>1
        varargout{2} = imObj; % can access this anyway from dispObj..
    end
end