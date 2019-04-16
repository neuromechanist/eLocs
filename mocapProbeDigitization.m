function elocs = mocapProbeDigitization(varargin)
% mocapProbeDigitization takes mocap probe digitization files and parse the
% electrode locations (elocs) on the cap.
%
% Requirements:
%           Matlab R2018a+, Statistics and Machine Learning Toolbox.
%           this function uses tables, with specific features that are
%           available from R2018a+. If you are at an earlier relase, let me
%           know, I'll try to make the compatible version.
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
%    'out': the structure that contains three tables containing elocs
%        out.zebris is the similar format as a zebris file.
%        out.tenTen contains elocs with the labels that are compatible
%        w/ the 10-10 system, so you can use EEGLAB's COREGISTER
%        function to fully warp the elocs.
%        out.adjustedLabels is the same as the zebris fule, but fiducial
%        names are changed to LPA, Nz and RPA for fiducial warping using
%        EEGLAB COREGISTER.
%        If neithe "out" is specified nor "saveF" (or if saveF = 0), the
%        function will save the eLocs to the same folder that it read the
%        proble files from.
%
% EXAMPLE:
%   mocapProbeDigitization('repoPath','~/probe/','subject','S1','savePath', ...
%                            '~/probe/output/','saveFlag',1);
%
%
% REV:
%       v0 @ 3/20/2019 adopted from runMocapZebris.m @
%       github.com/neuromechanist/digitization
%
% REFERENCE:
%       To use this toolbox, please cite:
%           Shirazi & Huang, bioRxiv, 557074, 2019, doi:10.1101/557074.
%
% Created by: Seyed Yahya Shirazi, BRaIN Lab, UCF
% email: shirazi@ieee.org
%
% Copyright 2019 Seyed Yahya Shirazi, UCF, Orlando, FL 32826

%% intialize

gTD = 0; % going to detail, plots additional figures during the process
win = 50; % sampling window of probe, a parameter set in Motive, to average over to get face marker positions.
strips = ["A","B","C","D"]; %strip letters
ne = 32; % number of electrodes in a strip
ngrd_fid = 5; % number of points, cms, drl, 3 fiducials
addpath(genpath(['code' filesep]));
addpath(genpath(['dependencies' filesep]));
fs = filesep;
fPath = pwd; % function path

    %% parse out the inputs
    opts = arg_define(varargin, ...
        arg({'repoPath','RepoPath','repository_path'},[fPath fs 'sample' fs 'probe' fs] ,[],'The repository containing folders w/ subject name.'), ...
        arg({'subj','Subject','subject'}, 'H2',[],'Default smaple is the Structure sensor.'), ...
        arg({'savePath','SavePath','save_path'}, [fPath fs 'sample' fs 'probe' fs 'output'],[],'The path for the electrode locations output'), ...
        arg({'saveFlag','save_flag','SaveFlag'}, 0,[0 1],'Save flag, change it to one if you need the eloc files'));
    
    p2l.repo = string(opts.repoPath);
    subj = string(opts.subj);
    p2l.probe = p2l.repo + subj + string(fs); 
    p2l.save = string(opts.savePath);
    saveF = opts.saveFlag;

    % if there is no output assigned when the finction is called and at the
    % same time save_flag is 0, the function should save the outputs in the
    % inputs directory.  
    if nargout == 0 && saveF == 0 
       p2l.save = p2l.probe; saveF = 1; 
    end

    %% create file paths
    % 5 optitrack take files, A, B, C, D, ground_fid
    for i = strips
        f2l.(i) = p2l.probe + subj + "_" + i + ".csv";
    end
    f2l.fid = p2l.probe + subj + "_fid.csv";
    f2l.save = p2l.save + subj;
    
    %% create electrode names
    chanlabels = string;
    for i = strips
        for j = 1:ne
            chanlabels(end+1) = i +  string(j); %#ok<*AGROW>
        end
    end
    chanlabels(1) = [];

%% import mocap .csv file for each strip and fiducials
for i = strips % loop through strips
    ieloc.(i) = importMocapTakeElocs(char(f2l.(i)),ne,win,gTD);
end
% ground, fiducials
fid = importMocapTakeElocs(f2l.fid,ngrd_fid,win,gTD);
    
%% concatenate mocap strips electrode location data
% each strip electrode locations are in ieloc and fid
%
% elocAll is a table of all electrode locations
% each row in elocAll is an electrode
% each cell in the elocAll table is a table of coords x,y,z
% for the face markers and electrode
% Because humans will move, we need to take into account the face markers
% at each electrode recording time
M = table; % a table of Markers of electrodes and fiducials
    for i = strips
        M = [M;ieloc.(i)];
    end
    M = [M;fid];
    mLabels = [chanlabels "cms" "drl" "lP" "nZ" "rP"]; % Marker labels
    M.Properties.RowNames = mLabels;

%% Sort and check face markers
% sometimes, face markers flip, left and right, and are need to be checked
% sort using Gaussian Mixture Model, there are sometimes that face markers
% switch, turn on the kM flag to use KMEANS function to sort them out.
% However, if the subject moves alot, this might also fail.
kM = 0;
[M.lM, M.fH, M.rM] = sortFaceMarkers(M.f1,M.f2,M.f3,kM,gTD);

% In case the subject moves very much or you havnt' set up the
% coordinate corrctly, you can assign the face markers manually, this
% however does not account for face marker swithces.
%     M.lM = M.f1;
%     M.fH = M.f2;
%     M.rM = M.f3;

%% Create head coordinate system and trasform elocs
mElocs = convertMocapPts2EeglabFormat(M,gTD);
    
%% create the output structure and saving the eloc files if requested

elocs = writeElocsEeglab_r2(mElocs,f2l.save,saveF);

