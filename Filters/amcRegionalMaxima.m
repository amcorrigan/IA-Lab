function lmax = amcRegionalMaxima(im,nhood,epsilon)

% my version of the regional maxima function which looks at the custom
% surrounding neighbourhood rather than defining connectivity

if nargin<3 || isempty(epsilon)
    epsilon = 0.001;
end

if ~iscell(nhood)
    dilim = imdilate(im,nhood);
else
    dilim = im;
    % allow multiple separable kernels to be supplied, to see if this is
    % faster
    for ii = 1:numel(nhood)
        dilim = imdilate(dilim,nhood{ii});
    end
end

lmax = im>((1-epsilon)*dilim);

