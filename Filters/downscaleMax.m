function im2 = downscaleMax(im,xyzfactors)

% downscale the image by an integer factor in each of the dimensions

imsize = size(im);
presize = xyzfactors.*ceil(imsize./xyzfactors);

% pad the array with -Infs at the end

padim = padarray(im,presize - imsize,-Inf,'post');

% the size should now be a multiple of the downscaling factor
outsize = presize./xyzfactors;

tempsize = [xyzfactors;outsize];
tempsize = tempsize(:)';

% break each dimension into two - the part that will be joined together
% during the max operation, and the part that will be left at the end
temp = reshape(padim,tempsize);

joinlist = num2cell(2*(1:numel(outsize)));

temp = joinDimensions(temp,joinlist);

im2 = max(temp,[],numel(outsize)+1);

