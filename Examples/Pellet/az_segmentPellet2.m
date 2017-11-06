function o_labelOutput = az_segmentPellet2(i_rgbImage, i_flagDebug)
%     i_rgbImage = imread('C:\Matlab_Works\2017-02-20 Pellet - Karen\Images\_MG_0368.JPG');

    if nargin <= 1
        i_flagDebug = false;
    end;

%%________________________________________________
%%  
    [M, N, ~] = size(i_rgbImage);

    rgbSmall = imresize(i_rgbImage, 0.25);

    hsi = rgb2hsi(rgbSmall);
    saturation = adapthisteq(hsi(:, :, 2));
%%________________________________________________
%%  Foreground
    processed = uh_processGray(imcomplement(saturation));

    %______________________________________________
    %   background correction
    SE = strel('disk', 20);
    gTophat = imcomplement(imtophat(processed,SE));
    processed = imadjust(gTophat);
    
    processed = imcomplement(imfill(imcomplement(processed), 'holes'));
    processed = imcomplement(wiener2(processed, [7 7]));

    %______________________________________________
    %   foreground
    foreground = uh_getThresholdPossian(processed);

    foreground = bwareaopen(foreground, 50);
    foreground = bwareaopen(~foreground, 50);    
%     foreground = imclearborder(foreground);
    
%%    
    if i_flagDebug == true
        figure, imshow(foreground);

        overlayed = imoverlay(imresize(i_rgbImage, 0.25), bwperim(foreground), [1 0 0], 2);
        figure, imshow(overlayed), title('foreground');
    end;
%%________________________________________________
%% 
    seed = imerode(foreground, strel('disk', 10));

    Lim = watershed(bwdist(seed));
    maskEmSeed = Lim == 0;
    
    bw = activecontour(saturation, seed, 200, 'Chan-Vese', 'ContractionBias', -0.2, 'SmoothFactor', 1);
%     o_overlayed = imoverlay(saturation, bwperim(bw), [0 0 1], 2);  
%     o_overlayed = imoverlay(o_overlayed, maskEmSeed, [1 0 0], 2);  
%     figure, imshow(o_overlayed);
%%________________________________________________
%% 
    o_binary = imresize(bw, [M, N]);
    
    o_binary = az_fourierDesp_IND(o_binary);
    o_binary(imresize(maskEmSeed, [M, N])) = false;

    o_binary = bwareafilt(o_binary, [1000, Inf]);    
    
    
    lPellet = bwlabel(o_binary);
    
    o_labelOutput{1} = lPellet;
  
    if i_flagDebug == true
        o_overlayed = imoverlay(i_rgbImage, bwperim(o_binary), [0 1 0], 4);  
        figure, imshow(o_overlayed);
    end
end

