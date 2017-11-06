classdef NoisySpheroid3DAZSeg < TwoStageAZSeg
    % try to remove the paraboloid of debris on the well surface before
    % segmenting the 3D spheroid
    properties
        Threshold = 0.01;
        SizeThresh = -1;
    end
    methods
        function this = NoisySpheroid3DAZSeg(thresh)
            this = this@TwoStageAZSeg({'Threshold','SizeThresh'},{'Threshold adjustment','Minimum Size'},[1.5,2],...
                'NoisySpheroid3D',1,0,1);
            
            if nargin>0 && ~isempty(thresh)
                this.Threshold = thresh;
            end
            
            this.DoLabelling = false;
            % don't use the default labelling step at the end
        end
       
        function fim = runStep1(this,im3d,L)
            
            % possible to supply the 2D estimate of the spheroid, eg from
            % bright field, as a starting point.
            if iscell(L) && ~isempty(L)
                L = L{1};
            end
            
            if iscell(im3d)
                im3d = im3d{1};
            end
            
            if isempty(L)
                % try to estimate where the spheroid is
                blim2 = sum(gaussFiltND(im3d,[20,20,5]),3);
                v = version;
                if str2double(v(1:4))<2014 || (str2double(v(1:4))==2014 && strcmpi(v(end),'a'))
                    bw = amcPropFilt(blim2>=multithresh(blim2),'Area',1);
                else
                    bw = bwareafilt(blim2>=multithresh(blim2),1);
                end
                
                
            else
                bw = L>0;
            end
            
            bw = imdilate(bw,ones(61,61));
            ww = 1-gaussFiltND(bw,[5,5]);
            debrisim = bsxfun(@times,ww,mat2gray(im3d));
            J = adaptHistEq3D(debrisim,[8,8,4],0.1);
            B = gaussFiltND(J,[40,40,2]);
            zz = maximage(B);
            zz(bw) = min(zz(:));
            bz = gaussFiltND(zz,[40,40]);
            
            % bz now contains an estimate of which slice the bottom of the
            % well is in for each column of pixels
            
            
            
            % all the steps up the threshold
            im2 = resize3(rangeNormalise(im3d),[1/3,1/3,1],'super');
            
            bz2 = resize3(bz,size(im2),'downlinear');
            
            zvals = reshape(1:size(bz2,3),[1,1,size(bz2,3)]);
            
            J = adaptHistEq3D(im2,[10,10,4],0.002);
            
            
            
% %             G = sqrt(gaussFiltND(J.^2,[2,2,0.5]));
% %             G2 = gaussFiltND(J,[3,3,1]);
            G = sqrt(gaussFiltND(J.^2,[2,2,0.5])) - gaussFiltND(J,[3,3,1]);
            % smoothing to enhance objects of the right size

            % could also try some scaling factor in front of the long scale
            % G
            
            wt = bsxfun(@(x,y)1-exp(-(x-y).^2/(2*2.5^2)),zvals,bz2);
            wt = imerode(wt,ones(31,31,1));
            
            fim = {G.*wt};
            
        end
        
        function L = runStep2(this,im3d,fim,L)
            % all the steps after the threshold
            if iscell(L) && ~isempty(L)
                L = L{1};
            end
            
            
            if iscell(im3d)
                im3d = im3d{1};
            end
            
            bw = fim{1};
            
            if ~isempty(L)
                % use the bright field estimate to constrain the region
                % where the spheroid can be
                maskbw = imresize(L>0,[size(bw,1),size(bw,2)],'nearest');
                maskbw = imdilate(maskbw,ones(25,25));
                
                bw = bsxfun(@and,bw,maskbw);
            end
            
            bw2 = imclose(bw,repmat(diskElement(1),[1,1,3]));

            % it is also this step that needs to join parts of the shell that aren't
            % quite touching
            % this was done previously via:
            % % bwdil = imdilate(imdilate(bw2,diskElement(2.5,1)),ones(1,1,3));
            bwdil = imdilate(imdilate(bw2,diskElement(1)),ones(1,1,3));

            % how does one decide the optimal scale for this dilation?
            % too big and neighbouring objects get joined together into a massive
            % object
            % too small and the large spheroids get broken into multiple objects

            % can possibly check for dodgy objects by looking at the distribution of
            % intensity in the shell of the label - if multiple objects have been
            % joined together, there will be lots of dark regions in the shell
            % if this is the case, replace the object with the previous underlying
            % labels (or the set of pixels from a smaller dilation operation)

            Ldil = bwlabeln(bwdil);
            L0 = Ldil.*bw2;

            % % L0 = bwlabeln(bw2);


%             L1 = bwareafilt(L0>0,1);
            if max(L0(:))>1
                % can't use bwareafilt for objects which might not be
                % contiguuous, have to use amc's propimage instead
                stats = regionprops(L0,'area');
                % remove any below the threshold
                L0 = propimage(L0,[stats.Area]==max([stats.Area]),0);
            end
            
            
            bw3 = convexHullLabel(L0)>0;
            % then smooth and relabel
            bw4 = gaussFiltND(bw3,[4,4,0.8])>0.5;
%             bw4 = bwareafilt(bw4,1);
            % bwareafilt only works in 2D??
            
            % need to make sure that only one label remains
            L1 = bwlabeln(bw4);
            if max(L1(:))>1
                stats = regionprops(L1,'area');
                avals = [stats.Area];
                maxind = avals==max(avals);
                if nnz(maxind)>1
                    maxind(find(maxind,nnz(maxind)-1,'last')) = 0;
                end

                L1 = propimage(L1,maxind,0);
            end
            
            L = resize3(L1,size(im3d),'nearest'); % some sort of smoothing after this would be good
            
            
            L = {L};
        end
    end
    methods (Static)
        function str = getDescription()
            str = ['Segmentation of 3D spheroids with a shell-like appearance','',...
                'Attempt to remove background debris before finding the spheroid',...
                'Threshold adjusment sets how bright an object is to be considered ',...
                'part of the spheroid.  Minimum size sets the minimum volume in pixels ',...
                'for a true spheroid.  Set the Minimum Size as a negative number to keep ',...
                'only the largest object (default behaviour)'];
        end
    end
    methods (Static)
        function bz = currentSandbox(imdata)
            blim2 = sum(gaussFiltND(imdata{1},[20,20,5]),3);
            bw = bwareafilt(blim2>=multithresh(blim2),1);
            bw = imdilate(bw,ones(61,61));
            ww = 1-gaussFiltND(bw,[5,5]);
            debrisim = bsxfun(@times,ww,mat2gray(imdata{1}));
            J = adaptHistEq3D(debrisim,[8,8,4],0.1);
            B = gaussFiltND(J,[40,40,2]);
            zz = maximage(B);
            zz(bw) = min(zz(:));
            bz = gaussFiltND(zz,[40,40]);
        end
        function [iix,val] = maximage(im)

            % return the index of the maximum value of the image in the last dimension.
            % Useful for looking at the outputs of a bunch of filters and picking the
            % one with the largest response, for example.

            sizim = size(im);

            dim = find(size(im)>1,1,'last');

            if dim>2
                % reshape into 2D
                im = reshape(im,[prod(sizim(1:(dim-1))),sizim(dim)]);
            end

            % sort
            [vv,iix] = sort(im,2,'descend');

            if dim>2
                iix = reshape(iix(:,1),sizim(1:dim-1));
            end
            if nargout>1
                if dim>2
                    val = reshape(vv(:,1),sizim(1:dim-1));
                else
                    val = vv(:,1);
                end
            end
        end
    end
end
