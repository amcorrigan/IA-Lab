function grayProcessed = az_processGray(i_gray, i_kernalSize)

    if nargin <= 1
        i_kernalSize = 5;
    end;

    se = strel('disk', i_kernalSize);

    %______________________________________________
    %
    fe = imerode(i_gray, se);
    fobr = imreconstruct(fe, i_gray);
    
    fobrc = imcomplement(fobr);
    fobrce = imerode(fobrc, se);
    grayProcessed = imreconstruct(fobrce, fobrc);
end