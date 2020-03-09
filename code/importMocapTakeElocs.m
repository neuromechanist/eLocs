function mTakeElocs = importMocapTakeElocs(mocapTakeFile,ne,win,gTD,label)

%% import raw data
hRows = 7; % header rows
fileID = fopen(mocapTakeFile,'r');
if ~exist('label','var') || isempty(label), label = "Unlabeled"; end

for r = 1:hRows
    header{r} = fgetl(fileID);
    N(r) = length(strfind(header{r}, ',')) + 1;
    tempvarnames{r} = regexp(header{r}, ',', 'split');
end

% keyboard;
fullvarnames{1} = tempvarnames{hRows}{1};
fullvarnames{2} = tempvarnames{hRows}{2};

% combine header lines to get all of the info for each column
for n = 3:N(hRows)
    % row 1 is system info, row 2 is blank
    fullvarnames{n} = [tempvarnames{3}{n} ',' tempvarnames{4}{n} ',' tempvarnames{5}{n} ',' tempvarnames{6}{n} ',' tempvarnames{7}{n}];
end

% system info
ct = 1;
for h = 1:2:length(tempvarnames{1})
    sysinfo{ct,1} = tempvarnames{1}{h};
    sysinfo{ct,2} = tempvarnames{1}{h+1};
    ct = ct+1;
end

% read in numerical data
frewind(fileID);
dataCell = textscan(fileID,'','Delimiter',',','HeaderLines',hRows,'EmptyValue', NaN );
fclose(fileID);

data = cell2mat(dataCell);

% keyboard
%% determine which unlabeled markers to use
% sometimes, the facemarkers can be blocked, creating extra unlabeled
% markers
uIdx = find(contains(fullvarnames,label)==1); % Unlabeled markers index
if mod(uIdx,3)~=0
    error("There is something wrong in Mocap data stream. Not all markers have x,y,z");
    return;
end

% keyboard

UP = data(:,uIdx); % unlabeled pool of markers, xyz coords

% probe measurements are in mm
UP = UP*1000; % convert from m to mm
nUP = length(uIdx)/3; % num of unlabeled markers

% calculate what percentage of the recording the electrode was tracked
% electrodes recorded at the end, A32, exist for less time and are tracked for a
% smaller percentage compared to electrodes recorded at the beginning, A1
percentTracked = nan(nUP,1);
for i = 1:nUP
    percentTracked(i) = 100-(sum(isnan(UP(:,i*3)))/length(UP)*100);
end

if gTD
    figure, plot(percentTracked,'o')
    ylabel('percent tracked'); xlabel('electrode number');
end

% keyboard;

%% find facemarkers
% doesn't matter if these are labeled and imported as left, right, forehead
% or if they switch due to lost tracking by people blocking the face
% markers. Will be clustered and relabeled below

fIdx = find(contains(fullvarnames,"face")==1); 

% we know there are 3 face markers
% here, it doesn't matter what is what
% also, convert from m to mm
face{1} = data(:,fIdx(1:3))*1000; 
face{2} = data(:,fIdx(4:6))*1000;
face{3} = data(:,fIdx(7:9))*1000;

% keyboard
%%  create tables for f1,f2,f3, and e
% you need the (x,y,z) for each face marker and the electrode of interest
% humans will move during the digitization so we must always use the
% facemarkers at the instance of the recording of the electrode location
% 3 face markers, f1, f2, f3
f1 = table; f1.X = nan(ne,1); f1.Y = nan(ne,1); f1.Z = nan(ne,1);
f2 = table; f2.X = nan(ne,1); f2.Y = nan(ne,1); f2.Z = nan(ne,1);
f3 = table; f3.X = nan(ne,1); f3.Y = nan(ne,1); f3.Z = nan(ne,1);
% electrode marker, e
e = table; e.X = nan(ne,1); e.Y = nan(ne,1); e.Z = nan(ne,1);

%% populate f1, f2, f3, e tables
% Sampling window from OptiTrack parameter, best value to average over to get face marker positions.
if ~exist('win','var') || isempty(win)
    win = 50; % optitrack measurement probe default is 50 samples
end
warning('off','MATLAB:table:RowsAddedNewVars');

% keyboard
for i = 1:nUP
    % find first non-NAN for the recording the the eloctrode location.
    % Instant the marker for that electrode location was created
    fNN(i) = find(~isnan(UP(:,i*3)),1,'first'); 
    f1{i,1:3} = nanmean(face{1}(fNN(i):fNN(i)+win,:)) ;
    f2{i,1:3} = nanmean(face{2}(fNN(i):fNN(i)+win,:)) ;
    f3{i,1:3} = nanmean(face{3}(fNN(i):fNN(i)+win,:)) ;
    e{i,1:3} = UP(fNN(i),i*3-2:i*3);
end
f1.Properties.VariableNames = {'X','Y','Z'};
f2.Properties.VariableNames = {'X','Y','Z'};
f3.Properties.VariableNames = {'X','Y','Z'};
e.Properties.VariableNames = {'X','Y','Z'};
% keyboard;

%% plots
if gTD
    figure('Name','Strip Markers with face marker fprm the first marker');
    plot3(e.X,e.Y,e.Z,'k.','MarkerSize',12,'DisplayName','elocs');
    hold on
    plot3([f1.X(1) f2.X(1) f3.X(1) f1.X(1)],[f1.Y(1) f2.Y(1) f3.Y(1) f1.Y(1)],[f1.Z(1) f2.Z(1) f3.Z(1) f1.Z(1)],'k--');
end
 
%% mTakeElocs is a table of tables
mTakeElocs = table; 
mTakeElocs.f1 = f1; mTakeElocs.f2 = f2; mTakeElocs.f3 = f3; 
mTakeElocs.e = e;
