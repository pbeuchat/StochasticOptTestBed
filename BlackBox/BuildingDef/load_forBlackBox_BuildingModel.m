%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     load_forBlackBox_BuildingModel.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnB , returnX0 , returnStateDef, returnConstraintParams , returnCostDef ] = load_forBlackBox_BuildingModel( inputBuildingIdentifierString , bbFullPath , sysOptions )

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
%



%% --------------------------------------------------------------------- %%
%% SPECIFY THE ROOT PATH WHERE THE REQUEST BUILDING DEFINITION IS LOCATED
thisBuildingDefFunctionString = [bbConstants.loadDefFunctionPrefix_forBuilding , inputBuildingIdentifierString , bbConstants.loadDefFolderSuffixTrue ];

thisBuildingDefFunctionHandle = str2func( thisBuildingDefFunctionString );

[returnB , returnX0 , returnStateDef, returnConstraintParams, returnCostDef, returnV, returnTmax , returnDims] = thisBuildingDefFunctionHandle( inputBuildingIdentifierString , bbFullPath , sysOptions );




end
%% END OF FUNCTION

