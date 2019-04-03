function mEloc = convertMocapPts2EeglabFormat(M,gTD)

%% use face markers to set current origin
% to account for people moving during the digitization
for i = 1:size(M,1)
    [fMM(i,:,:),eM(i,:)] = updateOrigin([M.lM{i,:};M.fH{i,:};M.rM{i,:}],M.e{i,:});
end
e2 = table(eM(:,1),eM(:,2),eM(:,3),'VariableNames',{'X','Y','Z'});
M.e2 = e2; % M is now f1 f2 f3 e lM fH rM e2

% keyboard
if gTD
    figure('Name','New Face markers, after sorted and transformed')
    plot3(squeeze(fMM(:,2,1)),squeeze(fMM(:,2,2)),squeeze(fMM(:,2,3)),'g.','MarkerSize',16,'DisplayName','forehead');
    hold on
    plot3(squeeze(fMM(:,1,1)),squeeze(fMM(:,1,2)),squeeze(fMM(:,1,3)),'b.','MarkerSize',16,'DisplayName','Left Marker');
    plot3(squeeze(fMM(:,3,1)),squeeze(fMM(:,3,2)),squeeze(fMM(:,3,2)),'r.','MarkerSize',16,'DisplayName','Right Marker');
    legend
end
if gTD
    figure('Name','Comparison of untransformed elocs to the transformed ones')
    plot3(M.e.X,M.e.Y,M.e.Z,'o','MarkerSize',10,'DisplayName','Original');
    hold on
    plot3(M.e2.X,M.e2.Y,M.e2.Z,'r.','MarkerSize',10,'DisplayName','Transformed');
end
% keyboard;
[~,eF] = updateOrigin([M.e2{'lP',:};M.e2{'nZ',:};M.e2{'rP',:}],M.e2.Variables);
% eF = table(eFi(:,1),eFi(:,2),eFi(:,3),'VariableNames',{'X','Y','Z'});
% eloc = addvars(eloc,eF);
M.eF = table(eF(:,1),eF(:,2),eF(:,3),'VariableNames',{'X','Y','Z'}); % M is now f1 f2 f3 e lM fH rM e2 eF

if gTD
    figure('Name','Final Outcome')
    plot3(M.eF.X,M.eF.Y,M.eF.Z,'.','MarkerSize',10,'DisplayName','Transformed');
end

mEloc = M.eF;
mEloc.Properties.RowNames = M.Properties.RowNames;

