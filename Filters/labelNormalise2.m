function nim = labelNormalise2(im,L,zeroval)

% normalize the image by subtracting off the mean and dividing by the
% standard deviation within each labelled region.

if nargin<3
    zeroval = [];
end

stats1 = regionprops(L,im,'MeanIntensity');
stats2 = regionprops(L,im.^2,'MeanIntensity');

meanim = propimage(L,[stats1.MeanIntensity]');
% % stdim = sqrt(propimage(L,[stats2.MeanIntensity]') - meanim.^2);
stdim = propimage(L,sqrt([stats2.MeanIntensity]' - [stats1.MeanIntensity]'.^2));

nim = (im - meanim)./stdim;

if ~isempty(zeroval)
    nim(isnan(nim)) = zeroval;
end


