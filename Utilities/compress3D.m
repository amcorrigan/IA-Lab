function rgb = compress3D(im3d,method)

if nargin<2 || isempty(method)
    method = 'bilinear';
end

% default to the method used by imgray (direct resizing)
switch lower(method)
    case 'max'
        % reshape so that the slices to be maximised are grouped together
        zdim = size(im3d,3);
        newzdim = 3*ceil(zdim/3);
        
        % pad with -Inf at the end so that it evenly divided into 3
        % could pad at either end to get more even sized slices?
        im3d = padarray(im3d,[0,0,newzdim-zdim],-Inf,'post');
        
        rgb = permute(max(...
            reshape(im3d,[size(im3d,1),size(im3d,2),newzdim/3,3]),...
            [],3),[1,2,4,3]);
    otherwise
        % reshape to be MxNx3 using bilinear interpolation
        rgb = permute(imresize(permute(im3d,[1 3 2]),...
            [size(im3d,1) 3],'bilinear'),[1 3 2]);
end