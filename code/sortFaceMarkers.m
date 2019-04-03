function [lM, fH, rM] = sortFaceMarkers(f1,f2,f3,kM,gTD)

%% cluster arbitrary face markers
fM = [f1;f2;f3]; % face markers
if gTD
    figure('Name','Face markers')
    
    plot3(f1.X,f1.Y,f1.Z,'.','MarkerSize',10,'DisplayName','f1');
    hold on
    plot3(f2.X,f2.Y,f2.Z,'.','MarkerSize',10,'DisplayName','f2');
    plot3(f3.X,f3.Y,f3.Z,'.','MarkerSize',10,'DisplayName','f3');
end


% Unless face markers are loose, they should move together, thereforre,
% each face marker should share the same covariation.
% In genreal k-means may fail to detect the face markers if the subject
% moved their head alot. So, let's have Gaussian distribution as default
% and turn on k-means only if necessary.
% fMg = cluster(fM_gM);
% pool = parpool;
% stream = RandStream('mlfg6331_64');
% options = statset('UseParallel',0,'UseSubstreams',1,'Streams',stream);
% fMg = kmeans(fM{:,:},3,'Options',options,'Replicates',10);
if kM
    fMg = kmeans(fM{:,:},3,'Replicates',10);
else
    fM_gM = fitgmdist(fM{:,:},3,'SharedCovariance',true,'Replicates',10,'Start','plus');
    fMg = cluster(fM_gM,fM{:,:});
end

for i = 1:length(fMg)/3
    fMg3(i,:) = [fMg(i) fMg(length(fMg)/3+i) fMg(2*length(fMg)/3+i)];
    fM3(i,:,:) = [fM{i,:}; fM{height(fM)/3+i,:}; fM{2*height(fM)/3+i,:}];
end
% keyboard;
for i = 1:length(fMg)/3
    f1{i,:} = transpose(squeeze(fM3(i,fMg3(i,:)==1,:)));
    f2{i,:} = transpose(squeeze(fM3(i,fMg3(i,:)==2,:)));
    f3{i,:} = transpose(squeeze(fM3(i,fMg3(i,:)==3,:)));
end

%% label face marker clusters
% *the forehead having the greatest y value (highest)
% *right marker, greatest x value (to the right)
% *left marker, smallest x value (to the left)
%
% this code only works if the mocap coordinate system is
% +x, to the right; -x, to the left
% +y, upwards in the vertical direction; -y, downwards
% +z, backwards/posterior; -z, forwards/anterior

if mean(f1.Y) > mean(f2.Y)
    if mean(f1.Y) > mean(f3.Y)
        fH = f1;
    else
        fH = f3;
    end
else
    if mean(f2.Y) > mean(f3.Y)
        fH = f2;
    else
        fH = f3;
    end
end

if mean(f1.X) > mean(f2.X)
    if mean(f1.X) > mean(f3.X)
        rM = f1;
    else
        rM = f3;
    end
else
    if mean(f2.X) > mean(f3.X)
        rM = f2;
    else
        rM = f3;
    end
end

if mean(f1.X) < mean(f2.X)
    if mean(f1.X) < mean(f3.X)
        lM = f1;
    else
        lM = f3;
    end
else
    if mean(f2.X) < mean(f3.X)
        lM = f2;
    else
        lM = f3;
    end
end

%% plot
if gTD
    hold on
    plot3(fH.X,fH.Y,fH.Z,'go','MarkerSize',10,'DisplayName','forhead');
    plot3(lM.X,lM.Y,lM.Z,'bo','MarkerSize',10,'DisplayName','Left Marker');
    plot3(rM.X,rM.Y,rM.Z,'ro','MarkerSize',10,'DisplayName','Right Marker');
    
    legend
end