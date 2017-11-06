function rgb = imobj2rgb(imobj)

% convert the image object to an rgb representation

% just get it working for now, then add options for the appearance
if iscell(imobj)
    imobj = imobj{1};
end

imdata = imobj.rawdata();

if ~iscell(imdata)
    imdata = {imdata};
end

cols = imobj.NativeColour;

if ~iscell(cols)
    cols = {cols};
end

rgb = zeros(size(imdata{1},1),size(imdata{1},2),3);

for ii = 1:numel(imdata)
    
    im2d = max(imdata{ii},[],3);
    
    normim = mat2gray(im2d,imquantile(im2d,[0.005,0.995]));
    
    rgb = max(rgb,bsxfun(@times,normim,reshape(cols{ii},[1,1,3])));
end