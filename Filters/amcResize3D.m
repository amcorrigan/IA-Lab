function imout = amcResize3D(im,newsize,method)

if nargin<3 || isempty(method)
    method = 'nearest';
end

% resize a 3D image, using the method specified (nearest neighbour to begin
% with)

% make a grid of the output size, scale the positions up and interpolate.

sizin = size(im);

if isempty(im)
    imout = [];
    return
end

if numel(sizin)==2
    sizin = [sizin, 1];
end

if numel(newsize)==1
    newsize = [1,1,1]*newsize;
end
newsize(newsize<=1) = sizin(newsize<=1).*newsize(newsize<=1);

if numel(newsize)<3
    newsize = [newsize,1];
end

newsize = ceil(newsize);

% [x,y,z] = amcMakeGrid(newsize);
x = 1:newsize(1);
y = 1:newsize(2);
z = 1:newsize(3);

% as long as we're not rotating, x y and z are independent

inx = (x-0.5)/newsize(1)*sizin(1) + 0.5;
iny = (y-0.5)/newsize(2)*sizin(2) + 0.5;
inz = (z-0.5)/newsize(3)*sizin(3) + 0.5;
% contains the coordinates of the new pixels in the old image
% these full arrays will be useful if we can avoid loops

switch lower(method)
    case 'nearest'
        inx(inx<0.5) = 1;
        inx(inx>sizin(1)) = sizin(1);
        
        iny(iny<0.5) = 1;
        iny(iny>sizin(2)) = sizin(2);
        
        inz(inz<0.5) = 1;
        inz(inz>sizin(3)) = sizin(3);
        
        imout = im(round(inx),round(iny),round(inz));
    
    case {'super','supersample','aa','antialias'}
        
        % only appropriate for downsizing images, or will approximate
        % nearest neighbour otherwise
        % might have to do this backwards, involving loops
%         error('Not completed yet!')
        
        % implement the code for 2x2x2, then generalise
        units = sizin./newsize;
        
        % cubic arrangement of subsampling, can rotate if we want.
        inxu = inx + 0.25*units(1);
        inxl = inx - 0.25*units(1);
        
        inyu = iny + 0.25*units(2);
        inyl = iny - 0.25*units(2);
        
        inzu = inz + 0.25*units(3);
        inzl = inz - 0.25*units(3);
        
        % if we're downsizing, these checks shouldn't be necessary
        inxu(inxu<0.5) = 1;
        inxu(inxu>sizin(1)) = sizin(1);
        
        inyu(inyu<0.5) = 1;
        inyu(inyu>sizin(2)) = sizin(2);
        
        inzu(inzu<0.5) = 1;
        inzu(inzu>sizin(3)) = sizin(3);
        
        inxl(inxl<0.5) = 1;
        inxl(inxl>sizin(1)) = sizin(1);
        
        inyl(inyl<0.5) = 1;
        inyl(inyl>sizin(2)) = sizin(2);
        
        inzl(inzl<0.5) = 1;
        inzl(inzl>sizin(3)) = sizin(3);
        
        inxl = round(inxl);
        inxu = round(inxu);
        inyl = round(inyl);
        inyu = round(inyu);
        inzl = round(inzl);
        inzu = round(inzu);
        
        imout = 0.125*(im(inxl,inyl,inzl) + ...
            im(inxl,inyl,inzu) + ...
            im(inxl,inyu,inzl) + ...
            im(inxl,inyu,inzu) + ...
            im(inxu,inyl,inzl) + ...
            im(inxu,inyl,inzu) + ...
            im(inxu,inyu,inzl) + ...
            im(inxu,inyu,inzu));
    case {'linear','trilinear'}
        % This would be better with a box filtering operation for the case
        % of downsizing.
        
        lowerx = floor(inx);
        upperx = ceil(inx);
        fracx = mod(inx,1);
        lowerx(lowerx<1) = 1;
        upperx(upperx>sizin(1)) = sizin(1);
        
        lowery = floor(iny);
        uppery = ceil(iny);
        fracy = mod(iny,1);
        lowery(lowery<1) = 1;
        uppery(uppery>sizin(2)) = sizin(2);
        
        lowerz = floor(inz);
        upperz = ceil(inz); %would lowerz+1 be quicker?
        fracz = mod(inz,1);
        lowerz(lowerz<1) = 1;
        upperz(upperz>sizin(3)) = sizin(3);
        
        [fx,fy,fz] = ndgrid(fracx,fracy,fracz);
        
        imout = im(lowerx,lowery,lowerz).*(1-fx).*(1-fy).*(1-fz) + ...
			im(upperx,lowery,lowerz).*(fx).*(1-fy).*(1-fz) + ...
			im(lowerx,uppery,lowerz).*(1-fx).*(fy).*(1-fz) + ...
			im(upperx,uppery,lowerz).*(fx).*(fy).*(1-fz) + ...
			im(lowerx,lowery,upperz).*(1-fx).*(1-fy).*(fz) + ...
			im(upperx,lowery,upperz).*(fx).*(1-fy).*(fz) + ...
			im(lowerx,uppery,upperz).*(1-fx).*(fy).*(fz) + ...
			im(upperx,uppery,upperz).*(fx).*(fy).*(fz);
    otherwise
        % This would be better with a box filtering operation for the case
        % of downsizing.
        boxsiz = sizin./newsize;
        % need to generate the kernel based on fractions of a pixel
        
        % will be slightly quicker to permute the image rather than
        % filtering in the second and third dimensions, like in gnfilt
        % or maybe do a gnfilt operation instead?
        if boxsiz(1)>1
            ss = odd(boxsiz(1),'down');
            endvals = (boxsiz(1)-ss)/2;
            kk = [endvals;ones(ss,1);endvals];
            im = imfilter(im,kk/sum(kk(:)),'same','replicate');
        end
        if boxsiz(2)>1
            ss = odd(boxsiz(2),'down');
            endvals = (boxsiz(2)-ss)/2;
            kk = [endvals;ones(ss,1);endvals]';
            im = imfilter(im,kk/sum(kk(:)),'same','replicate');
        end
        if boxsiz(3)>1
            ss = odd(boxsiz(3),'down');
            endvals = (boxsiz(3)-ss)/2;
            kk = permute([endvals;ones(ss,1);endvals],[3,2,1]);
            im = imfilter(im,kk/sum(kk(:)),'same','replicate');
        end
        
        
        lowerx = floor(inx);
        upperx = ceil(inx);
        fracx = mod(inx,1);
        lowerx(lowerx<1) = 1;
        upperx(upperx>sizin(1)) = sizin(1);
        
        lowery = floor(iny);
        uppery = ceil(iny);
        fracy = mod(iny,1);
        lowery(lowery<1) = 1;
        uppery(uppery>sizin(2)) = sizin(2);
        
        lowerz = floor(inz);
        upperz = ceil(inz); %would lowerz+1 be quicker?
        fracz = mod(inz,1);
        lowerz(lowerz<1) = 1;
        upperz(upperz>sizin(3)) = sizin(3);
        
        [fx,fy,fz] = ndgrid(fracx,fracy,fracz);
        
        imout = im(lowerx,lowery,lowerz).*(1-fx).*(1-fy).*(1-fz) + ...
			im(upperx,lowery,lowerz).*(fx).*(1-fy).*(1-fz) + ...
			im(lowerx,uppery,lowerz).*(1-fx).*(fy).*(1-fz) + ...
			im(upperx,uppery,lowerz).*(fx).*(fy).*(1-fz) + ...
			im(lowerx,lowery,upperz).*(1-fx).*(1-fy).*(fz) + ...
			im(upperx,lowery,upperz).*(fx).*(1-fy).*(fz) + ...
			im(lowerx,uppery,upperz).*(1-fx).*(fy).*(fz) + ...
			im(upperx,uppery,upperz).*(fx).*(fy).*(fz);
        
end


