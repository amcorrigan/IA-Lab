function [o_bwSpheroid, o_overlayed, detection] = segmentSpheroid_Dark(this, i_grayImage,i_imageType)
  
v = version('-release');
oldversion = str2double(v(1:4))<2014 || (str2double(v(1:4))==2014 && strcmpi(v(end),'a'));

%%_____________________________________________________________________________
%%  resize to be 25%
    [M, N] = size(i_grayImage);
    resizeFactor = 0.5;
    
    for method=[0,1,2]

    if method==1
        grayResized0 = imresize(i_grayImage, resizeFactor);
        [grayResized0,gdir]=imgradient(grayResized0);
        grayResized=-grayResized0+max(grayResized0(:));
        grayResized=grayResized/max(grayResized(:));
    elseif method==0
        grayResized = imresize(i_grayImage, resizeFactor);
    else
        grayResized00 = imresize(i_grayImage, resizeFactor);
        [grayResized0,gdir]=imgradient(grayResized00);
        grayResized=-grayResized0+max(grayResized0(:));
        grayResized=grayResized/max(grayResized(:));
        grayResized=grayResized+grayResized00/max(grayResized00(:));
        grayResized=grayResized/max(grayResized(:));
    end
    
    [m, n] = size(grayResized);
        
    %__________________________________________________________________________
    % 
    gray = im2uint8(grayResized);
    gray = (imcomplement(imcomplement(gray)));
    gray = imadjust(gray);
    
    %__________________________________________________________________________
    %   background correction
    SE = strel('disk', ceil(600 * resizeFactor));%400
    gTophat = gray;%imcomplement(imtophat(imcomplement(gray),SE));
    %gTophat = imcomplement(imtophat(imcomplement(gray),SE));
    gray = imadjust(gTophat);
    
    if method==1
        gray=conv2(double(gray),double(ones(11)/11^2),'Same');
    else
        gray=medfilt2(gray,[9,9]);
    end
    gray=imopen(gray,strel('disk',5));
    gray = imcomplement(imfill(imcomplement(gray), 'holes'));
    gray = wiener2(gray,[10 10]);
    
    %%%%%%%%% modelbased segmentation
%     minint=Inf;
%     for s=100:100:100
%     for x=3*s:s:size(gray,1)-3*s
%         %x
%         for y=3*s:s:size(gray,2)-3*s
%             G=zeros(size(gray));
%             G(x,y)=1;
%             D = bwdist(G);
%             G=D<s;
%             detected_components = bwconncomp(G);
%             properties = regionprops(detected_components,gray,'MeanIntensity');
%             if [properties.MeanIntensity]<minint
%                 minint=[properties.MeanIntensity];
%                 bestx=x;
%                 besty=y;
%                 bests=s;
%             end
%         end
%     end
%     end
%     [bestparams] = fminsearch(@(x)getintensity(x,gray),[bests,bestx,besty]);
%     G=zeros(size(gray));
%     G(round(bestparams(2)),round(bestparams(3)))=1;
%     D = bwdist(G);
%     G=D<bestparams(1);
%     %figure,subplot(1,2,1),imshow(gray,[]),subplot(1,2,2),imshow(G,[])
%     figure,imshow(imoverlay(gray/max(gray(:)), bwperim(G), [0 1 0], 2),[])
    %%%%%%%%%%%
   
%%_____________________________________________________________________________
%%  Watershed to get boundaries.
    edges = rangefilt(gray);
    if method==2
        maskIm = imextendedmin(gray, 50);
    else
        maskIm = imextendedmin(gray, 20);
    end
    STATS = regionprops(maskIm, 'Area');
    area = sort([STATS.Area]);
    len = size(area, 2);
    area15 = max(100, area(max(1, len-14)));
    areaLargest = max(area15, area(end));
    
    
    if oldversion
        maskIm = amcPropFilt(maskIm,'Area',[max(area15,areaLargest/100), areaLargest]);
    else
        maskIm = bwareafilt(maskIm, [max(area15,areaLargest/100), areaLargest]);
    end

    if sum(maskIm(1,:))==0
        maskIm(1,:)=1;
    elseif sum(maskIm(end,:))==0
        maskIm(end,:)=1;
    elseif sum(maskIm(:,1))==0
        maskIm(:,1)=1;
    elseif sum(maskIm(:,end))==0
        maskIm(:,end)=1;
    end
    
    if method==1
        I_mod = imimposemin(imfilter(edges.^2,fspecial('gaussian',11,3)),maskIm);
    elseif method==0
        I_mod = imimposemin(edges.^3,maskIm);
    else
        I_mod = imimposemin(edges, maskIm);
    end
    
    labelMatrix = watershed(I_mod);
    
%%_____________________________________________________________________________
%%    
    STATS = regionprops(labelMatrix, gray, 'Area', 'MeanIntensity');
    area = [STATS.Area];
    mInt = [STATS.MeanIntensity];
    mInt(area<500)=Inf;
    
    %__________________________________________________________________________
    %    Intensity filtering
    [~, intThresh] = uh_getThresholdPossian(gray);    

    [mIntSorted, indexmInt] = sort(mInt, 'Ascend');

    mIntSorted(mIntSorted > intThresh) = [];
%     if length(mIntSorted)>3
%         mIntSorted_end=mIntSorted(4:end);
%         mIntSorted_end(mIntSorted_end > intThresh) = [];
%         mIntSorted=[mIntSorted(1:3),mIntSorted_end];
%     end
    
    indexmInt = indexmInt(1:size(mIntSorted, 2));
    
    if ~isempty(indexmInt)
        %__________________________________________________________________________
        %   Seed for region growing
        seed = indexmInt(1);
        currentmInt = mIntSorted(1);
        currentArea = area(indexmInt(1));

        for i = 1:min(10,sum(mIntSorted<max(75,4*mIntSorted(1))))
        %nbr_dark=sum(mIntSorted<max(75,4*mIntSorted(1)));
        %for i = 1:min(10,max(nbr_dark,min(3,length(mIntSorted))))

            tempMask = false(m, n);

            for j = 1:length(seed)
                tempMask = tempMask | labelMatrix == seed(j);
            end
            tempMask = tempMask | labelMatrix == indexmInt(i);
        
            gray1D = reshape(gray, [1 m*n]);

            tempMask1D = reshape(tempMask, [1 m*n]);
            gray1D(~tempMask1D) = [];

            newmInt = mean(gray1D);
            newArea = length(gray1D);
            
            if newArea <= m * n * 0.25 

                seed = cat(1, seed, indexmInt(i));
                currentmInt = newmInt;
                currentArea = newArea;
            else
                break;
            end;
        end;
    
        %__________________________________________________________________________
        %
        newMask = false(m, n);

        for i = 1:length(seed)
            newMask = newMask | labelMatrix == seed(i);
        end
    
        bwSpheroid = newMask;
    
        bwSpheroid = imclose(bwSpheroid, ones(3, 3));
        bwSpheroid = imopen(bwSpheroid,strel('disk',10));

        STATS = regionprops(bwSpheroid, 'area');
        noRegions = size(STATS, 1);
    
    %%_____________________________________________________________________________
    %%  Exception check: 
        edgesMask = uh_getThresholdPossian(imcomplement(edges));
        edgesMask = imclearborder(edgesMask);
        edgesMask = imresize(edgesMask, [m, n]);
    
        % Quality of segmented object filter
        detected_components = bwconncomp(bwSpheroid);
        edge1=bwSpheroid([1,end],:);
        edge2=bwSpheroid(:,[1,end]);
        edgepixels=sum(edge1(:))+sum(edge2(:));
        if detected_components.NumObjects>0
            if edgepixels>mean([m,n])*0.25
                detected_components = bwconncomp(imclearborder(bwSpheroid));
            else
                cleared=imclearborder(bwSpheroid);
                cleared_components = bwconncomp(bwSpheroid & ~cleared);
                properties = regionprops(cleared_components, 'Area', 'Perimeter');
                roundness=4*[properties.Area]*pi./[properties.Perimeter].^2;
                [largest_area,largest]=max([properties.Area]);
                if roundness(largest)>0.75
                    detected_components = bwconncomp(bwSpheroid);
                else
                    detected_components = bwconncomp(imclearborder(bwSpheroid));
                end
            end
        end
        properties = regionprops(detected_components,gray, 'Area', 'Perimeter', 'Eccentricity', 'MeanIntensity');
        roundness=4*[properties.Area]*pi./[properties.Perimeter].^2;
        dark=([properties.MeanIntensity]<(min(gray(:))+0.6*(mean(gray(:))-min(gray(:))))) | [properties.MeanIntensity]==min([properties.MeanIntensity]);
        ecc=[properties.Eccentricity]<0.7;
        if length([properties.Area])>0
            [v,largest]=max([properties.Area]);
            E=[properties.Eccentricity];
            ecc(largest)=E(largest)<0.95;
            MI=[properties.MeanIntensity];
            dark(largest)=MI(largest)<(min(gray(:))+0.85*(mean(gray(:))-min(gray(:)))) | dark(largest);
        end
        is_good = find(roundness > 0 & ecc & [properties.Area]>500 & [properties.Area]<prod(size(bwSpheroid)) & dark);
        if length(is_good)>1
            A=[properties.Area]/v;
            MI=MI/max(MI);
            [best_total_value,best_total]=max(0.5*roundness(is_good)-0.5*E(is_good)+A(is_good)-MI(is_good));
            is_good=is_good(best_total);
        end        
        
        bwSpheroid = ismember(labelmatrix(detected_components), is_good);
        
        STATS = regionprops(bwSpheroid, 'area');
        noRegions = size(STATS, 1);
        
    else
        is_good=[];
    end
    if ~isempty(is_good)
        detection=1;
        
        if oldversion
            o_bwSpheroid = amcPropFilt({bwSpheroid, gray}, 'MeanIntensity', 1, 'smallest');
        else
            o_bwSpheroid = bwpropfilt(bwSpheroid, gray, 'MeanIntensity', 1, 'smallest');
        end
    
        for i = 1:min(noRegions, 5)-1
            %______________________________________________________________________
            %  Got the wrong spot based on min/mecan intensity??
            STATS = regionprops(o_bwSpheroid, 'area');

            if STATS.Area > 2250   %- 9000/4
             break;
            else
                if oldversion
                    temp1 = amcPropFilt({bwSpheroid, gray}, 'MeanIntensity', i+1, 'smallest');
                    temp2 = amcPropFilt({bwSpheroid, gray}, 'MeanIntensity', i, 'smallest');
                else
                    temp1 = bwpropfilt(bwSpheroid, gray, 'MeanIntensity', i+1, 'smallest');
                    temp2 = bwpropfilt(bwSpheroid, gray, 'MeanIntensity', i, 'smallest');
                end
                o_bwSpheroid = xor(temp1, temp2);
        
                edgeExistMask = edgesMask & o_bwSpheroid;

                if sum(edgeExistMask(:)) <= 30
                    o_bwSpheroid = false(m, n);
                    detection=0;
                    break;
                end;
            end;
        end;
    
        %__________________________________________________________________________
        %  Wrong segmentation: only got smooth background??
        edgeExistMask = edgesMask & o_bwSpheroid;

        if 0
            if sum(edgeExistMask(:)) <= 10
            o_bwSpheroid = false(M, N);
            detection=0;
            end;
        end
        %%_____________________________________________________________________________
        %%  Smoothing boundaries
        o_bwSpheroid = imresize(o_bwSpheroid, [M, N], 'bilinear');
        o_bwSpheroid = az_fourierDesp(o_bwSpheroid);

        o_overlayed = imoverlay(i_grayImage, bwperim(o_bwSpheroid), [0 1 0], 2);  
        
        
    else
        o_bwSpheroid = false(M,N);
        o_overlayed = i_grayImage;
        detection=0;
    end
    
    output{method+1}.detection=detection;
    output{method+1}.o_bwSpheroid=o_bwSpheroid;
    output{method+1}.o_overlayed=o_overlayed;
    detected_components = bwconncomp(o_bwSpheroid);
    properties = regionprops(detected_components,imresize(gray, [M, N], 'bilinear'), 'Area', 'Perimeter', 'Eccentricity', 'MeanIntensity',  'MinIntensity', 'MaxIntensity','PixelValues');
    
    output{method+1}.properties=properties;
    
    end
    
    if i_imageType==1
    [o_bwSpheroid, o_overlayed, detection] = select_method(output,m,1);
    else
        [o_bwSpheroid, o_overlayed, detection] = select_method(output,m,0);
    end
    
end