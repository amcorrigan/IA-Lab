function finalMask = az_fourierDesp_IND(i_binaryMask)

%%____________________________________________________
%%
    binaryMask = padarray(i_binaryMask, [50, 50], false, 'both');
    [M, N] = size(binaryMask);
    
    maskFourier = false(M, N);

    [bound, labelMat, ~, ~] = bwboundaries(binaryMask, 8, 'holes');
    STATS = regionprops(labelMat, 'Area', 'PixelList');
    
    area = [STATS.Area];
    
    pixelValue = zeros(size(STATS, 1), 1);
    
    for i = 1:size(STATS, 1)
        pixelList = STATS(i).PixelList;
    
        pValue = 0;
        for j = 1:size(pixelList, 1)
            pValue = pValue + (binaryMask(pixelList(j, 2), pixelList(j, 1)));
        end;
        pixelValue(i) = uint8(round(pValue ./ area(i)));
    end;
    
    clear labelMat STATS;
%%____________________________________________________
%%
    while(size(area, 2) > 0)

        [currentArea, maxIndex] = max(area);        
        
%         if (currentArea <= MIN_BLOCKSIZE) && (pixelValue(maxIndex) == 0)
% 
%             area(maxIndex) = [];
%             pixelValue(maxIndex) = [];
%             bound(maxIndex) = [];
%             
%             continue;
%         end;
        
        b = bound{maxIndex};

        x = max( min(b(:, 1)), 2 );
        y = max( min(b(:, 2)), 2 );
      
        boundLength = size(b, 1);

        %__________________________________
        %   Fourier and its inverse descriptor
        z = q_frdescp_GW(b);
        zz = q_ifrdescp_GW(z, uint16(real(sqrt(boundLength))-10));
        
        newImage = q_bound2im_GW(real(zz));
        newImage = bwmorph(newImage, 'bridge', 1);
        
        newImage = imfill(newImage, 'holes');
        [xw, yw] = size(newImage);
        
        %__________________________________
        %   If it is a hole
        if pixelValue(maxIndex) ~= 0
            maskFourier(x:(x+xw-1), y:(y+yw-1)) = maskFourier(x:(x+xw-1), y:(y+yw-1)) | newImage;
        else
            maskFourier(x:(x+xw-1), y:(y+yw-1)) = maskFourier(x:(x+xw-1), y:(y+yw-1)) & ~newImage;
        end;
        
        clear z zz newImage b;

        area(maxIndex) = [];
        pixelValue(maxIndex) = [];
        bound(maxIndex) = [];
        
%         enclosed_boundaries = find(A(:,maxIndex));
    end;
%%______________________________________
%%
    finalMask = maskFourier(51:end-50, 51:end-50);
   
    finalMask = bwareaopen(finalMask, 100, 8);
    
    