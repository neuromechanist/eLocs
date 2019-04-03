function [fidM,pcM] = updateOrigin(fidIn,pcIn)
% this function gets the fiducials of the head and outputs reoriented fiducials
% and electrode locations wrt the head coordinates. The convention is
% based on Zebris EIGuide software user manual page 15
%
% fid is a 3x3 matrix, rows are fid, col are x,y,z 
% [left preauricular (fidT9); nasion (Nz); right preauricular (fidT10)]

% pc is a nx3 vector, where n is the number of digitized points
% fidM and pcM are 3x3 and nx3 vectors respectively. not tables.
%
%   CAUTION: This function only will work on Matalb 2016b+ (due to
%   elementwise array expansion). If you are using an older version, change
%   the lines containig EAE with BSXFUN

%% input cannot be tables
if istable(fidIn)
    fid = table2array(fidIn);
else
    fid = fidIn; %already a matrix, not a table
end

if istable(pcIn)
    pc = table2array(pcIn);
else
    pc = pcIn; %already a matrix, not a table
end

lP = fid(1,:); nZ = fid(2,:); rP = fid(3,:);
%% the rest
pLine = createLine3d(lP,rP); % preauricular line
nOrig = projPointOnLine3d(nZ,pLine); % new (aka) head origin

% translating to origin
lP = lP - nOrig; nZ = nZ - nOrig; rP = rP - nOrig;
pc  = pc - nOrig;

% Z direction and rotation matrix
y = nZ; y = y / sqrt(sum(y.^2,2));
x = rP - lP; x = x / sqrt(sum(x.^2,2));
z = cross(x,y);  z = z / sqrt(sum(z.^2,2));
rotMat = [x;y;z]; % rotation matirx

% constructing output
fidM = round(transformPoint3d([lP;nZ;rP],rotMat),4);
pcM = round(transformPoint3d(pc,rotMat),4);

