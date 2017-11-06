function [o_Binary, o_thresh] = uh_getThresholdPossian(i_image, i_deleteMask)

%%_________________________________________
%%  Parse input
    if nargin <= 1
        i_deleteMask = [];
    end;
%%_________________________________________
%%
    if ndims(i_image) == 3
        i_image = rgb2gray(i_image);
    end

    if ~strcmp(class(i_image), 'uint8')
        i_image = im2uint8(i_image);   
    end;
    
    [M, N] = size(i_image);
    image1D = reshape(i_image, [1 M*N]);
    
    if ~isempty(i_deleteMask)
        image1D(i_deleteMask) = [];
    end;
    
    numBins = 256;
%%_________________________________________
%%
    totalPixels = numel(image1D);
    imageMin = double(min(image1D));
    imageMax = double(max(image1D));

    errorFunctionPois = zeros(numBins, 1);

    binMultiplier = numBins/(imageMax - imageMin);

    [relativeFrequency,~] = hist(double(image1D(:)), numBins);
    relativeFrequency = relativeFrequency/totalPixels;
    
    totalMean = mean2(image1D);
%%_________________________________________
%%
    for j = 1:numBins-1
        %get parameters for left mixture component (dark)
        priorLeft = 0;
        meanLeft = 0;
        priorLeft = priorLeft + realmin;

        for i = 1:j-1
            priorLeft = priorLeft + relativeFrequency(i);
            meanLeft = meanLeft + i*relativeFrequency(i);
        end
        meanLeft = meanLeft/priorLeft;

        %get parameters for right mixture component (bright)
        priorRight = 0;
        meanRight = 0;
        priorRight = priorRight + realmin;

        for i = j+1:numBins
            priorRight = priorRight + relativeFrequency(i);
            meanRight = meanRight + i*relativeFrequency(i);
        end
        meanRight = meanRight/priorRight;

        meanLeft = meanLeft + realmin;
        meanRight = meanRight + realmin;

        errorFunctionPois(j) = totalMean - priorLeft*(log(priorLeft) + meanLeft*log(meanLeft)) - priorRight*(log(priorRight) + meanRight*log(meanRight));
    end
%%_________________________________________
%%
    idx_poisson = 1;

    for j = 3:numBins - 2
        if errorFunctionPois(j) < errorFunctionPois(idx_poisson)
            idx_poisson = j;
        end
    end
%%_________________________________________
%%
    o_thresh = imageMin + idx_poisson/binMultiplier;
    o_Binary = false(size(i_image));
    o_Binary(i_image < o_thresh) = true;
end