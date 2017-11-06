function finalMask = az_fourierDesp(i_binaryMask)

%%____________________________________________________
%%
    binaryMask = padarray(i_binaryMask, [50, 50], false, 'both');
    [M, N] = size(binaryMask);
    
    maskFourier = false(M, N);

   bound = bwboundaries(binaryMask, 8, 'holes');
   
   %-- In case i_binaryMask is empty
   if isempty(bound)
       finalMask = i_binaryMask;
       return;
   end;
   
   bound = bound{1};
      
    boundLength = size(bound, 1);

    %__________________________________
    %   Fourier and its inverse descriptor
    z = q_frdescp_GW(bound);
%     zz = q_ifrdescp_GW(z, uint16(boundLength * 0.1));
    zz = q_ifrdescp_GW(z, uint16(real(sqrt(boundLength))));
        
    newImage = q_bound2im_GW(real(zz));
    newImage = bwmorph(newImage, 'bridge', 1);

    newImage = imfill(newImage, 'holes');
    [xw, yw] = size(newImage);


    x = max( min(bound(:, 1)), 2 );
    y = max( min(bound(:, 2)), 2 );

    maskFourier(x:(x+xw-1), y:(y+yw-1)) = xor(maskFourier(x:(x+xw-1), y:(y+yw-1)), newImage);
%%______________________________________
%%
    finalMask = maskFourier(51:end-50, 51:end-50);
  
end    