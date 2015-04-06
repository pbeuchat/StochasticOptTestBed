function [returnB , returnX0 , returnStateDef, returnConstraintParams , returnCostDef ] = load_forBlackBox_BuildingModel( inputBuildingIdentifierString , bbFullPath , sysOptions )
%  load_forBlackBox_BuildingModel.m
%  ---------------------------------------------------------------------  %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function runs the following sequence:
%                   - Check for an already saved model of the requested
%                     building
%                   - If not an already saved model then:
%                       - Generate a model from the Definition
%                       - Save the generated model
%                   - Else:
%                       - Load the saved model`
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
%% SPECIFY THE ROOT PATH WHERE THE REQUEST BUILDING DEFINITION IS LOCATED
thisBuildingDefFunctionString = [bbConstants.loadDefFunctionPrefix_forBuilding , inputBuildingIdentifierString , bbConstants.loadDefFolderSuffixTrue ];

thisBuildingDefFunctionHandle = str2func( thisBuildingDefFunctionString );

[returnB , returnX0 , returnStateDef, returnConstraintParams, returnCostDef, returnV, returnTmax , returnDims] = thisBuildingDefFunctionHandle( inputBuildingIdentifierString , bbFullPath , sysOptions );




end
%% END OF FUNCTION

