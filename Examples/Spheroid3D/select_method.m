function [o_bwSpheroid, o_overlayed, detection] = select_method(output,m,dark_spheroid)

if output{2}.detection==0 & output{3}.detection==0 % method 1 or none
        detection=output{1}.detection;
        o_bwSpheroid=output{1}.o_bwSpheroid;
        o_overlayed=output{1}.o_overlayed;
    elseif output{1}.detection==0 & output{3}.detection==0  % only method 2
        detection=output{2}.detection;
        o_bwSpheroid=output{2}.o_bwSpheroid;
        o_overlayed=output{2}.o_overlayed;
    elseif output{1}.detection==0 & output{2}.detection==0 % only method 3
        detection=output{3}.detection;
        o_bwSpheroid=output{3}.o_bwSpheroid;
        o_overlayed=output{3}.o_overlayed;
    elseif output{1}.detection==1 & output{2}.detection==1 & output{3}.detection==0 % 1 and 2
        p1=output{1}.properties;
        p2=output{2}.properties;
        q_round=([p1.Area]./[p1.Perimeter].^2) / ([p2.Area]./[p2.Perimeter].^2);
        q_dark=p2.MeanIntensity / p1.MeanIntensity;
        %q_dark=(p2.MeanIntensity/p2.processed_image_mean) / (p1.MeanIntensity/p1.processed_image_mean);
        q_ecc=p2.Eccentricity / p1.Eccentricity;
        q_size=p1.Area / p2.Area;
        q_range=(p2.MaxIntensity-p2.MinIntensity)/(p1.MaxIntensity-p1.MinIntensity);
        q_std=std(double([p2.PixelValues]))/std(double([p1.PixelValues]));
        bws=output{1}.o_bwSpheroid | output{2}.o_bwSpheroid;
        edge1=bws([1,end],:);
        edge2=bws(:,[1,end]);
        if sum(edge1(:))+sum(edge2(:))>m*0.04
            q_ecc=1;
        end
        %q=mean([q_round,q_dark,q_ecc,q_size]);
        %q=mean([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))]);
        q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(0.25);
        q=prod([q_round,q_dark,q_ecc,q_size])^(0.25);
        q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size])^(0.25);
        %q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size,q_std])^(1/5);
        %q=prod([min(3,max(1/3,q_round)),min(3,max(1/3,q_dark)),min(3,max(1/3,q_ecc)),min(3,max(1/3,q_size))])^(0.25);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(1/3);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_size))])^(1/3);
        if q>1
            detection=output{1}.detection;
            o_bwSpheroid=output{1}.o_bwSpheroid;
            o_overlayed=output{1}.o_overlayed;
        else
            detection=output{2}.detection;
            o_bwSpheroid=output{2}.o_bwSpheroid;
            o_overlayed=output{2}.o_overlayed;
        end
    elseif output{1}.detection==1 & output{2}.detection==0 & output{3}.detection==1 % 1 and 3
        p1=output{1}.properties;
        p2=output{3}.properties;
        q_round=([p1.Area]./[p1.Perimeter].^2) / ([p2.Area]./[p2.Perimeter].^2);
        q_dark=p2.MeanIntensity / p1.MeanIntensity;
        %q_dark=(p2.MeanIntensity/p2.processed_image_mean) / (p1.MeanIntensity/p1.processed_image_mean);
        q_ecc=p2.Eccentricity / p1.Eccentricity;
        q_size=p1.Area / p2.Area;
        q_range=(p2.MaxIntensity-p2.MinIntensity)/(p1.MaxIntensity-p1.MinIntensity);
        q_std=std(double([p2.PixelValues]))/std(double([p1.PixelValues]));
        bws=output{1}.o_bwSpheroid | output{3}.o_bwSpheroid;
        edge1=bws([1,end],:);
        edge2=bws(:,[1,end]);
        if sum(edge1(:))+sum(edge2(:))>m*0.04
            q_ecc=1;
        end
        %q=mean([q_round,q_dark,q_ecc,q_size]);
        %q=mean([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))]);
        q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(0.25);
        q=prod([q_round,q_dark,q_ecc,q_size])^(0.25);
        q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size])^(0.25);
        %q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size,q_std])^(1/5);
        %q=prod([min(3,max(1/3,q_round)),min(3,max(1/3,q_dark)),min(3,max(1/3,q_ecc)),min(3,max(1/3,q_size))])^(0.25);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(1/3);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_size))])^(1/3);
        if q>1
            detection=output{1}.detection;
            o_bwSpheroid=output{1}.o_bwSpheroid;
            o_overlayed=output{1}.o_overlayed;
        else
            detection=output{3}.detection;
            o_bwSpheroid=output{3}.o_bwSpheroid;
            o_overlayed=output{3}.o_overlayed;
        end
    elseif output{1}.detection==0 & output{2}.detection==1 & output{3}.detection==1 % 2 and 3
        p1=output{2}.properties;
        p2=output{3}.properties;
        q_round=([p1.Area]./[p1.Perimeter].^2) / ([p2.Area]./[p2.Perimeter].^2);
        q_dark=p2.MeanIntensity / p1.MeanIntensity;
        %q_dark=(p2.MeanIntensity/p2.processed_image_mean) / (p1.MeanIntensity/p1.processed_image_mean);
        q_ecc=p2.Eccentricity / p1.Eccentricity;
        q_size=p1.Area / p2.Area;
        q_range=(p2.MaxIntensity-p2.MinIntensity)/(p1.MaxIntensity-p1.MinIntensity);
        q_std=std(double([p2.PixelValues]))/std(double([p1.PixelValues]));
        bws=output{2}.o_bwSpheroid | output{3}.o_bwSpheroid;
        edge1=bws([1,end],:);
        edge2=bws(:,[1,end]);
        if sum(edge1(:))+sum(edge2(:))>m*0.04
            q_ecc=1;
        end
        %q=mean([q_round,q_dark,q_ecc,q_size]);
        %q=mean([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))]);
        q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(0.25);
        q=prod([q_round,q_dark,q_ecc,q_size])^(0.25);
        q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size])^(0.25);
        %q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size,q_std])^(1/5);
        %q=prod([min(3,max(1/3,q_round)),min(3,max(1/3,q_dark)),min(3,max(1/3,q_ecc)),min(3,max(1/3,q_size))])^(0.25);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(1/3);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_size))])^(1/3);
        if q>1
            detection=output{2}.detection;
            o_bwSpheroid=output{2}.o_bwSpheroid;
            o_overlayed=output{2}.o_overlayed;
        else
            detection=output{3}.detection;
            o_bwSpheroid=output{3}.o_bwSpheroid;
            o_overlayed=output{3}.o_overlayed;
        end
    else % all 3
        p1=output{1}.properties;
        p2=output{2}.properties;
        q_round=([p1.Area]./[p1.Perimeter].^2) / ([p2.Area]./[p2.Perimeter].^2);
        q_dark=p2.MeanIntensity / p1.MeanIntensity;
        %q_dark=(p2.MeanIntensity/p2.processed_image_mean) / (p1.MeanIntensity/p1.processed_image_mean);
        q_ecc=p2.Eccentricity / p1.Eccentricity;
        q_size=p1.Area / p2.Area;
        q_range=(p2.MaxIntensity-p2.MinIntensity)/(p1.MaxIntensity-p1.MinIntensity);
        q_std=std(double([p2.PixelValues]))/std(double([p1.PixelValues]));
        bws=output{1}.o_bwSpheroid | output{2}.o_bwSpheroid;
        edge1=bws([1,end],:);
        edge2=bws(:,[1,end]);
        if sum(edge1(:))+sum(edge2(:))>m*0.04
            q_ecc=1;
        end
        %q=mean([q_round,q_dark,q_ecc,q_size]);
        %q=mean([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))]);
        q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(0.25);
        q=prod([q_round,q_dark,q_ecc,q_size])^(0.25);
        q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size])^(0.25);
        %q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size,q_std])^(1/5);
        %q=prod([min(3,max(1/3,q_round)),min(3,max(1/3,q_dark)),min(3,max(1/3,q_ecc)),min(3,max(1/3,q_size))])^(0.25);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(1/3);
        %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_size))])^(1/3);
        if q>1
            p1=output{1}.properties;
            p2=output{3}.properties;
            q_round=([p1.Area]./[p1.Perimeter].^2) / ([p2.Area]./[p2.Perimeter].^2);
            q_dark=p2.MeanIntensity / p1.MeanIntensity;
            %q_dark=(p2.MeanIntensity/p2.processed_image_mean) / (p1.MeanIntensity/p1.processed_image_mean);
            q_ecc=p2.Eccentricity / p1.Eccentricity;
            q_size=p1.Area / p2.Area;
            q_range=(p2.MaxIntensity-p2.MinIntensity)/(p1.MaxIntensity-p1.MinIntensity);
            q_std=std(double([p2.PixelValues]))/std(double([p1.PixelValues]));
            bws=output{1}.o_bwSpheroid | output{3}.o_bwSpheroid;
            edge1=bws([1,end],:);
            edge2=bws(:,[1,end]);
            if sum(edge1(:))+sum(edge2(:))>m*0.04
                q_ecc=1;
            end
            %q=mean([q_round,q_dark,q_ecc,q_size]);
            %q=mean([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))]);
            q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(0.25);
            q=prod([q_round,q_dark,q_ecc,q_size])^(0.25);
            q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size])^(0.25);
            %q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size,q_std])^(1/5);
            %q=prod([min(3,max(1/3,q_round)),min(3,max(1/3,q_dark)),min(3,max(1/3,q_ecc)),min(3,max(1/3,q_size))])^(0.25);
            %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(1/3);
            %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_size))])^(1/3);
            if q>1
                detection=output{1}.detection;
                o_bwSpheroid=output{1}.o_bwSpheroid;
                o_overlayed=output{1}.o_overlayed;
            else
                detection=output{3}.detection;
                o_bwSpheroid=output{3}.o_bwSpheroid;
                o_overlayed=output{3}.o_overlayed;
            end
        else
            p1=output{2}.properties;
            p2=output{3}.properties;
            q_round=([p1.Area]./[p1.Perimeter].^2) / ([p2.Area]./[p2.Perimeter].^2);
            q_dark=p2.MeanIntensity / p1.MeanIntensity;
            %q_dark=(p2.MeanIntensity/p2.processed_image_mean) / (p1.MeanIntensity/p1.processed_image_mean);
            q_ecc=p2.Eccentricity / p1.Eccentricity;
            q_size=p1.Area / p2.Area;
            q_range=(p2.MaxIntensity-p2.MinIntensity)/(p1.MaxIntensity-p1.MinIntensity);
            q_std=std(double([p2.PixelValues]))/std(double([p1.PixelValues]));
            bws=output{2}.o_bwSpheroid | output{3}.o_bwSpheroid;
            edge1=bws([1,end],:);
            edge2=bws(:,[1,end]);
            if sum(edge1(:))+sum(edge2(:))>m*0.04
                q_ecc=1;
            end
            %q=mean([q_round,q_dark,q_ecc,q_size]);
            %q=mean([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))]);
            q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(0.25);
            q=prod([q_round,q_dark,q_ecc,q_size])^(0.25);
            q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size])^(0.25);
            %q=prod([q_round,min(3,max(1/3,q_dark)),q_ecc,q_size,q_std])^(1/5);
            %q=prod([min(3,max(1/3,q_round)),min(3,max(1/3,q_dark)),min(3,max(1/3,q_ecc)),min(3,max(1/3,q_size))])^(0.25);
            %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_ecc)),min(2,max(0.5,q_size))])^(1/3);
            %q=prod([min(2,max(0.5,q_round)),min(2,max(0.5,q_dark)),min(2,max(0.5,q_size))])^(1/3);
            if q>1
                detection=output{2}.detection;
                o_bwSpheroid=output{2}.o_bwSpheroid;
                o_overlayed=output{2}.o_overlayed;
                
            else
                detection=output{3}.detection;
                o_bwSpheroid=output{3}.o_bwSpheroid;
                o_overlayed=output{3}.o_overlayed;
                
            end
        end
    end

    
    %%%%%%%%%%% TEST att tvinga in den på metod 1 %%%%%%%%%%%%%%%%
    if dark_spheroid
    if output{1}.detection
    detection=output{1}.detection;
    o_bwSpheroid=output{1}.o_bwSpheroid;
    o_overlayed=output{1}.o_overlayed;
    end
    end

end




