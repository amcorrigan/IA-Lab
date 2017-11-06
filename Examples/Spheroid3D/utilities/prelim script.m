B = amcBilat3(imdata{1},[],4,0.01,16,4);
J = adaptHistEq3D(B,[12,12,4],0.04);
th = findthresh(J,imdata{1});

% alternative - this one might need some prefiltering to remove blurry
% regions (ie non nuclear textures)
N = rangeNormalise(imdata{1});
J = adaptHistEq3D(N,[12,12,4],0.02);
G = sqrt(gaussFiltND(J.^2,[6,6,2]));
G2 = gaussFiltND(J,[15,15,5]);
imgray(G-G2)


% with downscaling at the start, might help to clean things up a bit?
% try max resizing, and supersampling
% im2 = downscaleMax(rangeNormalise(imdata{1}),[3,3,1]);
im2 = resize3(rangeNormalise(imdata{1}),[1/3,1/3,1],'super');
J = adaptHistEq3D(im2,[8,8,4],0.001);
G = sqrt(gaussFiltND(J.^2,[2,2,0.5]));
G2 = gaussFiltND(J,[3,3,1]);

% could also try some scaling factor in front of the long scale L
th = findthresh(G-G2)
bw = (G-G2)>=th;

bw2 = imopen(imclose(bw,repmat(diskElement(3),[1,1,3])),diskElement(3,[1,1,3]));

L = bwlabeln(bw2);
L2 = convextHullLabel(L);


D = bwdistsc(bw2,[1,1,5]);
lmax = D>20;
D2 = bwdistsc(~bw2,[1,1,5]);
Lw = watershed(imimposemin(D2-D,lmax));


L = bwlabeln(bw);
cmap = jet(max(L(:)));
cmap = cmap(randperm(size(cmap,1)),:);
figure
for ii = 1:size(cmap,1)
    fv(ii) = surfcapsstruct(L==ii,[1,1,5]);
    p(ii) = patch(fv(ii),'facecolor',cmap(ii,:),'edgecolor','none');
    ii
end


% % J = adaptHistEq3D(im2,[12,12,4],0.02);
% % G = sqrt(gaussFiltND(J.^2,[6,6,2]));
% % L = gaussFiltND(J,[15,15,5]);
% % imgray(G-L)

