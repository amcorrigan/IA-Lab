function level = amcGrayThresh(im)

% like matlab's version, but allows negative values
[nim,lims] = rangeNormalise(im);
tlev = graythresh(nim);

level = (lims(2)-lims(1))*tlev + lims(1);