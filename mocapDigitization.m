function localEloc = mocapDigitization(varargin)
% mocapDigitization takes a mocap digitization file and parse the
% electrode locations (elocs) on the cap.
%
% Requirements:
%           Matlab R2017b+, Statistics and Machine Learning Toolbox.
%           This function uses tables, with features available from
%           R2017b+. If you are at an earlier relase, let me know, I'll try
%           to make the compatible version. 
%
% INPUT:
%       Inputs are names pairs:
%   'repoPath' : repository path, the path that contains the subject
%       folders. for example if the scans are for the subject S1, the path
%       to the scan will be: "repoPath/S1/". Default is the sample folder
%       included in the toolbox.
%
%   'subject' : the name of the subject as a character array. Default
%       is S1 which is the smaple file for the Structure scan.
%       
%   'savePath' : The path that the files should be saved there. The
%       function does not create the path, rather uses it. Default is the
%       "output" folder avaible in the "sample" path of the toolbox.
%
%   'saveFlag' : whether the files are saved or not, default is 0, so it is
%       NOT saving your output.
%       
% OUTPUT:
%    'localELoc': locations of the markers (excluding the face markers) that are
%    detected on the cap. Please note that the current version of this
%    function is NOT capable of identification of the specific electrode
%    names. Locations are wrt to the face markers and are in the local
%    coordinates.
%
% EXAMPLE:
%   mocapDigitization('repoPath','~/mocap/','subject','M1','savePath', ...
%                            '~/mocap/output/','saveFlag',1);
%
%
% REV:
%       v0 @ 3/3/2020 adopted from runMocapZebris.m @
%       github.com/neuromechanist/digitization
%
% REFERENCE:
%       To use this toolbox, please cite:
%           Shirazi & Huang, bioRxiv, 557074, 2019, doi:10.1101/557074.
%
% Created by: Seyed Yahya Shirazi, BRaIN Lab, UCF
% email: shirazi@ieee.org
%
% Copyright 2020 Seyed Yahya Shirazi, UCF, Orlando, FL 32826
%% intialize

gTD = 0; % going to detail, plots additional figures during the process
win = 50; % sampling window of probe, a parameter set in Motive, to average over to get face marker positions.
ne = 36; % number of electrodes in a strip
addpath(genpath(['code' filesep]));
addpath(genpath(['dependencies' filesep]));
fs = filesep;
fPath = pwd; % function path

    %% parse out the inputs
    opts = arg_define(varargin, ...
        arg({'repoPath','RepoPath','repository_path'},[fPath fs 'sample' fs 'mocap' fs] ,[],'The repository containing folders w/ subject name.'), ...
        arg({'subj','Subject','subject'}, 'M1',[],'Default smaple is the Structure sensor.'), ...
        arg({'savePath','SavePath','save_path'}, [],[],'The path for the electrode locations output'), ...
        arg({'saveFlag','save_flag','SaveFlag'}, 0,[0 1],'Save flag, change it to one if you need the eloc files'));
    
    p2l.repo = string(opts.repoPath);
    subj = string(opts.subj);
    p2l.mocap = p2l.repo + subj + string(fs); 
    if isempty(opts.savePath), opts.savePath = p2l.mocap; end
    p2l.save = string(opts.savePath);
    saveF = opts.saveFlag;

    % if there is no output assigned when the finction is called and at the
    % same time save_flag is 0, the function should save the outputs in the
    % inputs directory.  
    if nargout == 0 && saveF == 0 
       p2l.save = p2l.mocap; saveF = 1; 
    end
    f2l.mocap = p2l.mocap + subj + ".csv";
    f2l.save = p2l.save + subj;
    
%% import mocap .csv file wrt the face markers
% please make sure that in your mocap csv files, you aready marked your
% face markers as "face" and the markers on the eeg cap (as well as the
% fiducials) are the only UNLABELED markers. Then, having known how many
% unlabeled markers are there for a gvien setup, the following function
% would give their coordinates as well together with the face markers.
% In case that you want to have the fiducials seperately, you can label
% them as "fid" in the mocap and run and uncomment the script in line 94:

ieloc = importMocapTakeElocs(char(f2l.mocap),ne,win,gTD,"Unlabeled");
% ifid = importMocapTakeElocs(char(f2l.mocap),ne,win,gTD,"fid");

%% convert the electrode location form global to local
% To convert the electrode locations form the global to local coordinates,
% we need to use the face markers as the new local cooridnates:

% first find which face marker is which
[ieloc.lM, ieloc.fH, ieloc.rM] = sortFaceMarkers(ieloc.f1,ieloc.f2,ieloc.f3,1,gTD); 
% then let's convert global coord. to local:
for i = 1:size(ieloc,1)
    [~,lE(i,:)] = updateOrigin([ieloc.lM{i,:};ieloc.fH{i,:};ieloc.rM{i,:}],ieloc.e{i,:});
end
localEloc = table(lE(:,1),lE(:,2),lE(:,3),'VariableNames',{'X','Y','Z'});

%% save the local electrode locations
if saveF, save(f2l.save,'localEloc'); end
    