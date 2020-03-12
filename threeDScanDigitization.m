function elocs = threeDScanDigitization(varargin)
% threeDScanDigitization takes 3D scans from the head (using Strucutre or others)
% and runs through the Fieldtrip toolbox fucntion for digitization.
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
%       "output" folder available in the "sample" path of the toolbox.
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
%   threeDScanDigitization('repoPath','~/scan/','subject','S1','savePath', ...
%                            '~/scan/output/','saveFlag',1);
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
%
% Created by: Seyed Yahya Shirazi, BRaIN Lab, UCF
% email: shirazi@ieee.org
%
% Copyright 2019 Seyed Yahya Shirazi, UCF, Orlando, FL 32826

%% intialize
strips = ["A","B","C","D"]; %strip letters
ne = 32; % number of electrodes in a strip
addpath(genpath(['code' filesep]));
addpath(genpath(['dependencies' filesep]));
ft_defaults;
fs = filesep;
fPath = pwd; % function path

    %% parse out the inputs

    opts = arg_define(varargin, ...
        arg({'repoPath','RepoPath','repository_path'},[fPath fs 'sample' fs 'threeD' fs] ,[],'The repository containing folders w/ subject names.'), ...
        arg({'subj','Subject','subject'}, 'S1',[],'Default smaple is the Structure sensor.'), ...
        arg({'savePath','SavePath','save_path'}, [],[],'The path for the electrode locations output'), ...
        arg({'saveFlag','save_flag','SaveFlag'}, 0,[0 1],'Save flag, 1 to save in save Path, 0 to ignore'));
    p2l.repo = string([opts.repoPath fs]);
    subj = string(opts.subj);
    p2l.scan = p2l.repo + subj + string(fs);
    if isempty(opts.savePath), opts.savePath = p2l.scan; end
    p2l.save = string(opts.savePath);
    saveF = opts.saveFlag;
    
    % if there is no output assigned when the finction is called and at the
    % same time save_flag is 0, the function should save the outputs in the
    % inputs directory.
    if nargout == 0 && saveF == 0
        p2l.save = p2l.scan; saveF = 1;
    end
        
    %% create file paths and load data
    f2l.all = dir(char(p2l.scan));
    f2l.nameString = string({f2l.all.name});
    if find(contains(string({f2l.all.name}),"Model","IgnoreCase",true)) % make sure that "model" is not a directory, this happens for the structure scan
        dirFlag = [f2l.all.isdir];
        if find(dirFlag(contains(f2l.nameString,"model","IgnoreCase",true)))
            p2l.scan = p2l.scan + "model" + string(fs);
            f2l.all = dir(char(p2l.scan));
            f2l.nameString = string({f2l.all.name});
        end
    end
    
    if find(contains(string({f2l.all.name}),"mtl")) % Structure.io scan
        f2l.scan = p2l.scan + f2l.nameString(find(contains(f2l.nameString,"obj"),1));
        
    elseif find(contains(string({f2l.all.name}),"ply",'IgnoreCase',true)) % Einscan or any other ply file
        f2l.scan = p2l.scan + f2l.nameString(find(contains(f2l.nameString,"ply"),1));
    else
        error("No scanned shape detected. Check your direcotry.")
    end
    
    headMesh = ft_read_headshape(char(f2l.scan)); % load the mesh, it takes a while
    % our Einscan is slready in milimeter, but if you want to convert it
    headMesh = ft_convert_units(headMesh,'mm');
    
    f2l.save = p2l.save + subj; % output file name needs to have a subject identifier

    
%% pick the fiducials
% First choose Left PA, then n and lastly Right PA
config = [];
config.method = 'headshape';
warning("mark LPA, Nz and RPA repectively");
fid = ft_electrodeplacement(config,headMesh);

%% reorient the mesh to the fiducials coordinate system
config = [];
config.method = 'fiducial';
config.coordsys = 'ctf';

config.fiducial.lpa = fid.elecpos(1,:);
config.fiducial.nas = fid.elecpos(2,:);
config.fiducial.rpa = fid.elecpos(3,:);
headMesh = ft_meshrealign(config,headMesh);

    %% check axes
    figure
    ft_plot_axes(headMesh)
    ft_plot_mesh(headMesh)
    
%% mark the electrodes
% Choose in Strip Order (A -> B -> C -> D, then CMS, DRL, Left PA, Nasion & Right PA)
config = [];
config.method = 'headshape';

warning("Mark the electrodes in order A-->D \& then CMS, DRL, LPA, Nz & RPA");
digitizedHead = ft_electrodeplacement(config,headMesh);
%electrode labels
chanlabels = [];
for i = 1:length(strips)
    for j = 1:ne
        chanlabels{(i-1)*ne+j} = [char(strips(i)) int2str(j)]; %#ok<*AGROW>
    end
end
chanlabels = [chanlabels,{'cms','drl','lP','nZ','rP'}];

digitizedHead.label = chanlabels;

    %% check eloc
    figure;
    ft_plot_mesh(headMesh)
    ft_plot_sens(digitizedHead)
%% moving electrodes inward
config = [];
config.method = 'moveinward';
config.moveinward = 7.65; % this is measured on BioSemi.
config.elec = digitizedHead;
digitizedHead = ft_electroderealign(config);

    %% check eloc
    figure;
    ft_plot_mesh(headMesh)
    ft_plot_sens(digitizedHead)

%% create the output structure and saving the eloc files if requested

X = digitizedHead.chanpos(:,1); Y = digitizedHead.chanpos(:,2); Z = digitizedHead.chanpos(:,3);
chanPosT = table(X,Y,Z,'RowNames',digitizedHead.label); % channles position table
[~,chanPosT.Variables] = updateOrigin(chanPosT{{'lP','nZ','rP'},:},chanPosT.Variables);

elocs = writeElocsEeglab_r2(chanPosT,f2l.save,saveF);


        