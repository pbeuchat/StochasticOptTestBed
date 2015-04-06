
function [myConstants] = constants_ForBlackBox()
%  constants_ForBlackBox.m
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > Some paths, file name preffixes and other things
%               required
% ----------------------------------------------------------------------- %
% This file is part of the Stochastic Optimisation Test Bed.
%
% The Stochastic Optimisation Test Bed - Copyright (C) 2015 Paul Beuchat
%
% The Stochastic Optimisation Test Bed is free software: you can
% redistribute it and/or modify it under the terms of the GNU General
% Public License as published by the Free Software Foundation, either
% version 3 of the License, or (at your option) any later version.
% 
% The Stochastic Optimisation Test Bed is distributed in the hope that it
% will be useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with the Stochastic Optimisation Test Bed.  If not, see
% <http://www.gnu.org/licenses/>.
%  ---------------------------------------------------------------------  %



clear myConstants

%% --------------------------------------------------------------------- %%
%% FILE and FOLDER NAMES
myConstants.saveDefPrefix               = 'savedModel_ForBuildingID_';
myConstants.saveDefExtension            = '.mat';

myConstants.loadDefFolderPrefix         = 'Def_';
myConstants.loadDefFolderSuffixTrue     = '_True';
myConstants.loadDefFolderSuffixError    = '_withModelError';
