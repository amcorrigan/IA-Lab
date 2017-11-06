function showim(data,labels)

if nargin<2
    labels = [];
end

if isempty(labels)
    imobj = createImObj(data);
    imobj.showImage();
else
    imobj = createImObj(data);
    
    labelobj = autoLabelObj(labels);
    
    anim = cAnnotatedImage(imobj,labelobj);
    
    anim.showImage();
    
end

