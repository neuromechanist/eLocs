function out = writeElocsEeglab_r2(mElocs,SaveFile,saveF)
% change log: rev2- going back to genereating (almost same) .sfp  file that
% Zebris makes to make sure that eeglab works with the file as intended.
fidData = mElocs({'lP' 'nZ' 'rP'},:);
fidData.Properties.RowNames = {'LPA','Nz','RPA'};

% we know that last 5 rows of mElocs is
% cms, drl, lP, nZ, rP
% so all of the electrode data is before that
sfpData = mElocs(1:end-5,:);

if saveF
writetable(fidData,SaveFile + "_eeglabformat_final.fid",'FileType','text','WriteVariableNames',0,...
    'WriteRowNames',1,'Delimiter','tab');
writetable(sfpData,SaveFile + "_eeglabformat_final.sfp",'FileType','text','WriteVariableNames',0,...
    'WriteRowNames',1,'Delimiter','tab');
end

%% Corrected Zebris
% Current BRaIN Lab ICA pipline starts at A1 as the first channel number
% (EEG.chanloc.urchan). To be constent with that, we moved fiduclas to the
% very bottom of the file. As we also checked, it is still compatible with
% EEGLAB chanread funtion and does not make any problem. It also has LPA,
% NZ and RPA as the labels for fiducuals.
out.correctedZebris = [sfpData;fidData];

if saveF
writetable(out.correctedZebris,SaveFile + "_corrected.sfp",'FileType','text','WriteVariableNames',0,...
    'WriteRowNames',1,'Delimiter','tab');
end

%% Zebris output
load('zebris_labels2.mat','zLabel2');
out.zebris = [sfpData;fidData];
out.zebris.Properties.RowNames = zLabel2{:};

if saveF
writetable(out.zebris,SaveFile + ".sfp",'FileType','text','WriteVariableNames',0,...
    'WriteRowNames',1,'Delimiter','tab');
end

%% Adjusted Labels
% COREGISTER function for EEGLAB DIPFIT process, warps electrode locations
% to match to the template. However, it needs the exact same names like the
% 10-20 convenction. Zebris file has those labels in paratheses, so, in
% order to make the warping more realsitic, we substituted channel names
% with the their alternative labeles (if there is one of course).
load('zebris_labels3.mat','zLabel3');
out.adjustedLabels = out.zebris;
out.adjustedLabels.Properties.RowNames = zLabel3{:};
if saveF
writetable(out.zebris,SaveFile +"_AdjustedLabels.sfp",'FileType','text','WriteVariableNames',0,...
    'WriteRowNames',1,'Delimiter','tab');
end
