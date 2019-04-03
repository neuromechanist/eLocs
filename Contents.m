% eLocs
% Version 1.0.0_beta	March-26-2019 .
%
% eLocs toolbox/add-on helps you to digitize EEG electrode locations
% (elocs) using 3D scanners and motion capture probe. The toolbox was
% tested on MATLAB R2018b and contains every dependencies needed to run.
% However, you need to have relevant MATLAB toolboxes installed.
%
% The main functions of this toolbox are in the root directory. Each main
% function should add path of the files it needs, so there should not be a
% need to add the other folders. Main functions take name pairs as the
% input. Running each main function without any input will run the function
% with the example inputs adn default settings.
%
%
% Required toolboxes are: 
%       1- Statistics and Machine Learning Toolbox
%
% There are currently two functions for digitization:
%       1- mocapProbeDigitization: this function provides a pipeline to
%       digtize using motion capture probe. The probe is a digitizing wand
%       with fixed markers on top, origianlly provided by OptiTrack. The
%       file should work seamlessly with OptiTrack-provided files. We would
%       be happy to help develop the code for other systems with a
%       digitizing probe.
%
%       2- threeDScanDigitization: After scanning the head with the cap,
%       you can pass the folder containting the scan to this function to
%       start the digitizing process in MATLAB. The function accpets any
%       PLY file, specificaaly, as the PLY reader for this toolbox is
%       optimised over the original available on the FieldTrip toolbox for
%       a much faster read. You can also point to the folder that contains
%       the files provided by the Structure sensor and you will get to
%       digitized the colored-scan in the MATLAB environment.
%
% Citation:
%       Please cite the following preprint for using this toolbox:
%       S. Y. Shirazi and H. J. Huang, “More Reliable EEG Electrode
%       Digitizing Methods Can Reduce Source Estimation Uncertainty, But
%       Current Methods Already Accurately Identify Brodmann Areas”
%       bioRxiv, 557074, Feb. 2019, doi: http://dx.doi.org/10.1101/557074
%
% Credits: importMocapTakeElocs.m was written by Dr. Helen J Huang. Dr.
% Huang inspired the project and provided numerous edits for the toolbox
%
%
% Created by: Seyed Yahya Shirazi, BRaIN Lab, UCF
% email: shirazi@ieee.org
%
% Copyright 2019 Seyed Yahya Shirazi, UCF, Orlando, FL 32826

help('Contents');
