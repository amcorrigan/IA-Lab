% FILTERS
%
% Files
%   adbilat            - fast bilateral filtering, taking advantage of MATLAB's efficiency of
%   addborder2absolute - return a structure which contains border information for the different
%   adgaussgrad2       - x and y gradients
%   adgraythresh       - like matlab's version, but allows negative values
%   adresize           - prototype function for N-dimensional resizing
%   adwshed            - 
%   diamel             - specifying the size separately is useful for if we want to subtract this
%   FastDoGProc2       - 2D DoG filter
%   gausskern          - oversampling of 10x by default
%   gnfilt             - N-dimensional Gaussian filtering, permuting the image rather than the
%   ImProcND           - override the code that separates the calls based on dimensionality,
%   makegrid2          - makegrid (because it uses ndgrid) can be very memory intensive (the
%   newdiscel          - keep the inputs the same, but don't yet have a use for the bin input -
%   normalise          - 
%   NullProc           - 
%   rescale            - Linearly rescale values in an array
%   rescalelabels      - rescale the label array so that there are no gaps in the numbers, useful
%   resize3            - 
%   scdilate2          - perform a fast dilation by first shrinking the image taking the maxima
%   scregmax2          - my version of the regional maxima function which looks at the custom
