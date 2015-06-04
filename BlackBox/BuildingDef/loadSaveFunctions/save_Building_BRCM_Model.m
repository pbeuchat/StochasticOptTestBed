function [returnSuccess] = save_Building_BRCM_Model( inputBuildingIdentifierString , inputB , bbFullPath )
%  save_Building_BRCM_Model.m
%  ---------------------------------------------------------------------  %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        03-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%
%  DESCRIPTION: > This functions combines the input varaible into one
%               struct and saves that into the "SavedDef" folder
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



%% --------------------------------------------------------------------- %%
%% PUT TOGETHER THE STRUCT TO BE SAVE TO FILE
clear savedData;
savedData       = struct();
savedData.B     = inputB;

%% --------------------------------------------------------------------- %%
%% SAVE THE CONSTRUCT VARIABLE ("savedData") TO FILE

% Construct the string for the name of the bulding model save fjle
saveFileName = [ bbConstants.saveDefPrefix , inputBuildingIdentifierString , bbConstants.saveDefExtension ];

% Construct the path for the save folder
savePath = [bbFullPath , '/' , 'BlackBox/BuildingDef/SavedDef'];

% First check if a file with the same name exists
% (Note: the folder where it is located should already be on the path)
existResult = exist( saveFileName , 'file' );

% If it exists then delete the exsting file of the same name
if (existResult == 2)
    % Keep the user updated
    disp(' ... NOTE: this same building model has been saved previously, the previous save is been deleted');
    % Delete the old file
    delete(saveFileName);
    % Save
end

% Save the data to file
save([savePath,'/',saveFileName],'savedData','-v7.3');

% Keep the memory clear
clear savedData;


%% SET THE RETURN VARIABLES
% If we made it to here then things were successful
returnSuccess = true;


%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
%  HOW TO USE:  1) ...
%
% INPUTS:
%       > xxx
%
% OUTPUTS:
%       > yyy
