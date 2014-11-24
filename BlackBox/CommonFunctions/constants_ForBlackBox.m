%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     constants_ForBlackBox.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [myConstants] = constants_ForBlackBox()

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > Some paths, file name preffixes and other things
%               required
%               

clear myConstants

%% --------------------------------------------------------------------- %%
%% FILE and FOLDER NAMES
myConstants.saveDefPrefix               = 'savedModel_ForBuildingID_';
myConstants.saveDefExtension            = '.mat';

myConstants.loadDefFolderPrefix         = 'Def_';
myConstants.loadDefFolderSuffixTrue     = '_True';
myConstants.loadDefFolderSuffixError    = '_withModelError';
